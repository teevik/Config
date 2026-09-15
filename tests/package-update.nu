use std/assert
use test-utils.nu [with-scratch assert-success]

def owned-files [] {
    [flake.lock packages/opencode-desktop.nix packages/opencode.nix packages/t3code-nightly.nix]
}

def contents [root: path] {
    owned-files | each {|file| {file: $file, content: (open --raw ($root | path join $file))} }
}

def calls [] { open --raw $env.MOCK_LOG | lines | each { from json } }

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
        let baseline = ($scratch | path join 'starting checkout')
        mkdir $baseline
        cp --recursive ($source | path join packages) $baseline
        ^chmod -R u+w $baseline
        {fixture: 'preexisting lock edit'} | to json | save ($baseline | path join flake.lock)
        "\n# preexisting user edit\n" | save --append ($baseline | path join packages/t3code-nightly.nix)
        'unrelated user file' | save ($baseline | path join unrelated.txt)
        ^chmod 640 ($baseline | path join packages/opencode.nix)
        let before = (contents $baseline)

        let checkout = ($scratch | path join 'successful checkout')
        let exported = ($scratch | path join 'validated update')
        cp --recursive $baseline $checkout
        assert-success (run-update $checkout [--export $exported])
        assert ((calls | where tool == nix | get args) == [
            [flake update]
            [build --no-link --print-build-logs --file packages/update-targets.nix opencode opencode-desktop omp t3code-nightly]
        ])
        assert equal (calls | where tool == nix-update | length) 1
        let after = (contents $checkout)
        assert ($after != $before)
        assert (open --raw ($checkout | path join packages/t3code-nightly.nix) | str contains '# preexisting user edit')
        assert equal (open --raw ($checkout | path join unrelated.txt)) 'unrelated user file'
        let cli = (open --raw ($checkout | path join packages/opencode.nix))
        let desktop = (open --raw ($checkout | path join packages/opencode-desktop.nix))
        for arch in [x64 arm64] {
            let digest = ('sha256-' + ($arch | hash sha256 --binary | encode base64))
            assert ($cli | str contains $digest)
            assert ($desktop | str contains $digest)
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
        assert equal (calls | where tool == nix | get args) [[flake update]]
        assert equal (contents $quick) $after
        print 'PASS: source-only updates refresh all inputs and skip validation builds'

        for failure in [flake npm curl nix-update build] {
            let work = ($scratch | path join $"failed-($failure)")
            let output = ($scratch | path join $"export-($failure)")
            cp --recursive $baseline $work
            let result = (run-update $work [--export $output] $failure)
            assert ($result.exit_code != 0)
            assert ($result.stderr | str contains 'completed edits were kept')
            assert not ($output | path exists)
            assert equal (open --raw ($work | path join unrelated.txt)) 'unrelated user file'
            assert (open --raw ($work | path join packages/t3code-nightly.nix) | str contains '# preexisting user edit')
            if $failure == 'flake' {
                assert equal (contents $work) $before
            } else {
                assert equal (open --raw ($work | path join flake.lock) | from json).fixture updated
            }
            if $failure in [flake npm curl] {
                assert equal (open --raw ($work | path join packages/opencode.nix)) $before.2.content
                assert equal (calls | where tool == nix-update | length) 0
            } else {
                assert equal (contents $work) $after
            }
            if $failure != 'build' {
                assert equal (calls | where {|call| $call.tool == 'nix' and $call.args.0 == 'build' } | length) 0
            }
        }
        print 'PASS: failures at each stage stop later work, retain completed edits, and produce no export'

        for release in [mismatch missing-assets invalid-digest missing-digest invalid-integrity invalid-json] {
            let work = ($scratch | path join $release)
            cp --recursive $baseline $work
            assert ((run-update $work [] '' $release).exit_code != 0)
            assert equal (contents $work | skip 1) ($before | skip 1)
            assert equal (calls | where tool == nix-update | length) 0
        }
        let drift = ($scratch | path join drift)
        cp --recursive $baseline $drift
        $before.2.content | save --append ($drift | path join packages/opencode.nix)
        let drift_before = (contents $drift | skip 1)
        assert ((run-update $drift []).exit_code != 0)
        assert equal (contents $drift | skip 1) $drift_before
        print 'PASS: release mismatch, missing assets/digests, malformed hashes/JSON, and source-layout drift preserve package files'

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
