use std/assert
use test-utils.nu [with-scratch assert-success t3-source t3-tags]

def owned-files [] {
    [flake.lock packages/opencode-desktop.nix packages/opencode.nix packages/roc-nightly.nix packages/t3code-nightly.nix]
}

def contents [root: path] {
    owned-files | each {|file| {file: $file, content: (open --raw ($root | path join $file))} }
}

def calls [] { open --raw $env.MOCK_LOG | lines | each { from json } }

# Nix commands other than evaluations and T3 Code's dependency builds.
def nix-actions [] {
    calls | where {|call| $call.tool == 'nix' and $call.args.0 != 'eval' and '--keep-going' not-in $call.args } | get args
}

def opencode-files [entries: list] { $entries | where file =~ opencode }

def run-update [checkout: path, args: list<string>, failure: string = '', release: string = 'valid'] {
    '' | save --force $env.MOCK_LOG
    with-env {MOCK_UPDATE_WORKFLOW: '1', MOCK_FAILURE: $failure, MOCK_RELEASE: $release} {
        ^$nu.current-exe --no-config-file ($checkout | path join packages/update.nu) ...$args | complete
    }
}

def main [source: path] {
    let source = ($source | path expand)
    with-scratch {|scratch|
        $env.MOCK_LOG = ($scratch | path join calls.jsonl)
        $env.MOCK_T3 = ($scratch | path join t3-fixture)
        $env.MOCK_TAGS = (t3-tags [v0.0.99-nightly.20261001.42])
        t3-source $env.MOCK_T3 0.0.99-nightly.20261001.42 'fixture lock' 'fixture licenses'
        let baseline = ($scratch | path join 'starting checkout')
        mkdir $baseline
        cp --recursive ($source | path join packages) $baseline
        ^chmod -R u+w $baseline
        '{ outputs = _: {}; }' | save ($baseline | path join flake.nix)
        {fixture: 'preexisting lock edit'} | to json | save ($baseline | path join flake.lock)
        "\n# preexisting user edit\n" | save --append ($baseline | path join packages/t3code-nightly.nix)
        'unrelated user file' | save ($baseline | path join unrelated.txt)
        ^chmod 640 ($baseline | path join packages/opencode.nix)
        let before = (contents $baseline)

        let checkout = ($scratch | path join 'successful checkout')
        let exported = ($scratch | path join 'validated update')
        cp --recursive $baseline $checkout
        assert-success (run-update $checkout [--export $exported])
        assert ((nix-actions) == [
            [flake update]
            [build --no-link --print-build-logs --file packages/update-targets.nix opencode opencode-desktop roc-nightly t3code-nightly]
        ])
        assert equal (calls | where tool == fetch | get args | flatten) [src pnpmDeps licenseNotices]
        let after = (contents $checkout)
        assert ($after != $before)
        let t3 = (open --raw ($checkout | path join packages/t3code-nightly.nix))
        assert ($t3 | str contains '# preexisting user edit')
        assert ($t3 | str contains 'version = "0.0.99-nightly.20261001.42";')
        assert equal (open --raw ($checkout | path join unrelated.txt)) 'unrelated user file'
        let cli = (open --raw ($checkout | path join packages/opencode.nix))
        let desktop = (open --raw ($checkout | path join packages/opencode-desktop.nix))
        let roc = (open --raw ($checkout | path join packages/roc-nightly.nix))
        assert ($roc | str contains '2026-10-01-abcdef0')
        for arch in [x64 arm64] {
            let digest = ('sha256-' + ($arch | hash sha256 --binary | encode base64))
            assert ($cli | str contains $digest)
            assert ($desktop | str contains $digest)
            assert ($roc | str contains $digest)
        }
        assert equal (open --raw ($exported | path join files.txt) | lines) (owned-files)
        let payload = ($exported | path join sources)
        assert equal (glob $"($payload)/**/*" --no-dir | each { path relative-to $payload } | sort) (owned-files)
        assert equal (contents $payload) $after
        assert equal (^stat --format=%a ($payload | path join packages/opencode.nix) | str trim) '640'
        let restored = ($scratch | path join restored)
        mkdir $restored
        ^cp -a ($payload + '/.') $restored
        assert equal (contents $restored) $after
        assert-success (run-update $checkout [])
        assert equal (contents $checkout) $after
        print 'PASS: all-input refresh, package validation, exact export/restore, modes, dirty edits, and no-change rerun'

        let quick = ($scratch | path join 'source only')
        cp --recursive $baseline $quick
        assert-success (run-update $quick [--no-build])
        assert equal (nix-actions) [[flake update]]
        assert equal (contents $quick) $after
        print 'PASS: source-only updates refresh all inputs and skip validation builds'

        # Hosted runners can exhaust the shared unauthenticated GitHub quota.
        # Drive the real updater through a release endpoint that requires auth.
        let authenticated = ($scratch | path join 'authenticated metadata')
        cp --recursive $baseline $authenticated
        with-env {GITHUB_TOKEN: 'fixture-read-only-token'} {
            assert-success (run-update $authenticated [--no-build] '' 'require-auth')
        }
        assert equal (contents $authenticated) $after
        assert not (open --raw $env.MOCK_LOG | str contains 'fixture-read-only-token')
        print 'PASS: GitHub release metadata uses the read-only token without putting it in command arguments'

        let skipped = ($scratch | path join 'inputs already refreshed')
        cp --recursive $baseline $skipped
        assert-success (run-update $skipped [--skip-inputs --no-build])
        assert ([flake update] not-in (calls | where tool == nix | get args))
        assert equal (open --raw ($skipped | path join flake.lock)) $before.0.content
        assert equal (contents $skipped | skip 1) ($after | skip 1)
        print 'PASS: --skip-inputs keeps the existing lock and still refreshes package sources'

        # Chains run in parallel, so a failure keeps the other chains' edits. T3
        # Code waits for the input refresh; validation waits for everything.
        let untouched = {
            flake: [flake.lock packages/t3code-nightly.nix]
            npm: [packages/opencode-desktop.nix packages/opencode.nix]
            integrity: [packages/opencode-desktop.nix packages/opencode.nix]
            curl: [packages/opencode-desktop.nix packages/opencode.nix packages/roc-nightly.nix]
            git: [packages/t3code-nightly.nix]
            build: []
        }
        for failure in ($untouched | columns) {
            let work = ($scratch | path join $"failed-($failure)")
            let output = ($scratch | path join $"export-($failure)")
            cp --recursive $baseline $work
            let result = (run-update $work [--export $output] $failure)
            assert ($result.exit_code != 0)
            assert ($result.stderr | str contains 'completed edits were kept')
            assert not ($output | path exists)
            assert equal (open --raw ($work | path join unrelated.txt)) 'unrelated user file'
            assert (open --raw ($work | path join packages/t3code-nightly.nix) | str contains '# preexisting user edit')
            let kept = ($untouched | get $failure)
            let expected = ($before | zip $after | each {|pair| if $pair.0.file in $kept { $pair.0 } else { $pair.1 } })
            assert equal (contents $work) $expected
            if $failure != 'build' {
                assert equal (nix-actions | where {|args| $args.0 == 'build' } | length) 0
            }
        }
        print 'PASS: failures keep independent edits, skip validation, and produce no export'

        for release in [mismatch missing-assets invalid-digest missing-digest invalid-integrity invalid-json] {
            let work = ($scratch | path join $release)
            cp --recursive $baseline $work
            assert ((run-update $work [] '' $release).exit_code != 0)
            assert equal (opencode-files (contents $work)) (opencode-files $before)
        }
        let drift = ($scratch | path join drift)
        cp --recursive $baseline $drift
        $before.2.content | save --append ($drift | path join packages/opencode.nix)
        let drift_before = (opencode-files (contents $drift))
        assert ((run-update $drift []).exit_code != 0)
        assert equal (opencode-files (contents $drift)) $drift_before
        print 'PASS: release mismatch, missing assets/digests, malformed hashes/JSON, and source-layout drift preserve package files'

        for release in [roc-invalid-tag roc-missing-arm64 roc-invalid-digest roc-missing-digest roc-duplicate-asset] {
            let work = ($scratch | path join $release)
            cp --recursive $baseline $work
            assert ((run-update $work [] '' $release).exit_code != 0)
            assert equal (open --raw ($work | path join packages/roc-nightly.nix)) $before.3.content
        }
        let roc_drift = ($scratch | path join roc-drift)
        cp --recursive $baseline $roc_drift
        $before.3.content | save --append ($roc_drift | path join packages/roc-nightly.nix)
        let roc_before = (open --raw ($roc_drift | path join packages/roc-nightly.nix))
        assert ((run-update $roc_drift []).exit_code != 0)
        assert equal (open --raw ($roc_drift | path join packages/roc-nightly.nix)) $roc_before
        print 'PASS: Roc tag, both architectures, digest validation, duplicate assets, and source drift are checked before writing'

        for args in [[--no-build --export $exported] [--export $exported] [--unknown]] {
            assert ((run-update $checkout $args).exit_code != 0)
            assert equal (calls | length) 0
            assert equal (contents $checkout) $after
            assert equal (contents $payload) $after
        }
        assert equal (glob $"($scratch)/.package-update.*" | length) 0
        assert equal (glob $"($checkout)/packages/.opencode-update.*" | length) 0
        print 'PASS: invalid options and existing exports fail before mutation; staging files are cleaned'
    }
}
