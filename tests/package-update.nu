use std/assert
use test-utils.nu [with-scratch assert-success t3-source t3-tags]

def owned-files [] {
    [flake.lock packages/roc-nightly.nix packages/t3code-nightly.nix]
}

def contents [root: path] {
    owned-files | each {|file| {file: $file, content: (open --raw ($root | path join $file))} }
}

# The exported manifest, payload file list, and failure labels.
def exported [output: path] {
    let payload = ($output | path join sources)
    {
        manifest: (open --raw ($output | path join files.txt) | lines)
        payload: (glob $"($payload)/**/*" --no-dir | each { path relative-to $payload } | sort)
        failed: (open ($output | path join failures.json) | get label)
    }
}

def validation-builds [] { nix-actions | where {|args| $args.0 == 'build' } }

def calls [] { open --raw $env.MOCK_LOG | lines | each { from json } }

# Nix commands other than evaluations and T3 Code's dependency builds.
def nix-actions [] {
    calls | where {|call| $call.tool == 'nix' and $call.args.0 != 'eval' and '--keep-going' not-in $call.args } | get args
}

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
        ^chmod 640 ($baseline | path join packages/roc-nightly.nix)
        let before = (contents $baseline)

        let checkout = ($scratch | path join 'successful checkout')
        let exported = ($scratch | path join 'validated update')
        cp --recursive $baseline $checkout
        assert-success (run-update $checkout [--export $exported])
        assert ((nix-actions) == [
            [flake update]
            [build --no-link --print-build-logs --file packages/nu-scripts/update-targets.nix roc-nightly t3code-nightly]
        ])
        assert equal (calls | where tool == fetch | get args | flatten) [src pnpmDeps licenseNotices]
        let after = (contents $checkout)
        assert ($after != $before)
        let t3 = (open --raw ($checkout | path join packages/t3code-nightly.nix))
        assert ($t3 | str contains '# preexisting user edit')
        assert ($t3 | str contains 'version = "0.0.99-nightly.20261001.42";')
        assert equal (open --raw ($checkout | path join unrelated.txt)) 'unrelated user file'
        let roc = (open --raw ($checkout | path join packages/roc-nightly.nix))
        assert ($roc | str contains '2026-10-01-abcdef0')
        for arch in [x64 arm64] {
            let digest = ('sha256-' + ($arch | hash sha256 --binary | encode base64))
            assert ($roc | str contains $digest)
        }
        assert equal (exported $exported) {manifest: (owned-files), payload: (owned-files), failed: []}
        assert equal (open --raw ($exported | path join failures.json) | from json) []
        let payload = ($exported | path join sources)
        assert equal (contents $payload) $after
        assert equal (^stat --format=%a ($payload | path join packages/roc-nightly.nix) | str trim) '640'
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

        # Chains run in parallel and each step leaves its files updated or
        # untouched. T3 Code waits for the input refresh, so an input failure
        # fails its chain too. Whatever succeeded is validated and exported.
        let partial = {
            flake: {failed: ['all flake inputs' 'T3 Code nightly'], kept: [flake.lock packages/t3code-nightly.nix], targets: [roc-nightly]}
            git: {failed: ['T3 Code nightly'], kept: [packages/t3code-nightly.nix], targets: [roc-nightly]}
            fetch: {failed: ['T3 Code nightly'], kept: [packages/t3code-nightly.nix], targets: [roc-nightly]}
            curl: {failed: ['Roc nightly'], kept: [packages/roc-nightly.nix], targets: [t3code-nightly]}
        }
        for failure in ($partial | columns) {
            let case = ($partial | get $failure)
            let work = ($scratch | path join $"failed-($failure)")
            let output = ($scratch | path join $"export-($failure)")
            cp --recursive $baseline $work
            assert-success (run-update $work [--export $output] $failure)
            let expected = ($before | zip $after | each {|pair| if $pair.0.file in $case.kept { $pair.0 } else { $pair.1 } })
            assert equal (contents $work) $expected
            assert equal (open --raw ($work | path join unrelated.txt)) 'unrelated user file'
            assert (open --raw ($work | path join packages/t3code-nightly.nix) | str contains '# preexisting user edit')
            assert equal (validation-builds) [[build --no-link --print-build-logs --file packages/nu-scripts/update-targets.nix ...$case.targets]]
            let files = (owned-files | where {|file| $file not-in $case.kept })
            assert equal (exported $output) {manifest: $files, payload: $files, failed: $case.failed}
            let payload = ($output | path join sources)
            assert equal ($files | each {|file| open --raw ($payload | path join $file) }) ($files | each {|file| open --raw ($work | path join $file) })
            let errors = (open ($output | path join failures.json) | get error)
            assert ($errors.0 | str contains (if $failure == fetch { 'T3 Code dependency build failed' } else { $"mock ($failure) failure" }))
            if $failure == flake { assert ($errors.1 | str contains 'Skipped because all flake inputs failed') }
        }
        print 'PASS: a failed chain is left out of validation and export, and recorded in failures.json'

        # Without an export there is no failure record, so the exit status reports it.
        let unexported = ($scratch | path join 'failed without export')
        cp --recursive $baseline $unexported
        let result = (run-update $unexported [] curl)
        assert ($result.exit_code != 0)
        assert ($result.stderr | str contains 'Roc nightly')
        assert equal (validation-builds) [[build --no-link --print-build-logs --file packages/nu-scripts/update-targets.nix t3code-nightly]]
        assert equal (contents $unexported) ($after | update 1 $before.1)
        print 'PASS: a partial failure without an export validates the rest and still exits non-zero'

        for case in [
            {failure: 'flake,curl', args: []}
            {failure: 'git,curl', args: [--skip-inputs]}
        ] {
            let work = ($scratch | path join $"all-failed-($case.failure)")
            let output = ($scratch | path join $"export-all-failed-($case.failure)")
            cp --recursive $baseline $work
            let result = (run-update $work [...$case.args --export $output] $case.failure)
            assert ($result.exit_code != 0)
            assert ($result.stderr | str contains 'No update succeeded')
            assert ($result.stderr | str contains 'Roc nightly')
            assert not ($output | path exists)
            assert equal (validation-builds) []
            assert equal (contents $work) $before
        }

        let invalid = ($scratch | path join 'failed validation')
        let output = ($scratch | path join 'export-failed-validation')
        cp --recursive $baseline $invalid
        let result = (run-update $invalid [--export $output] build)
        assert ($result.exit_code != 0)
        assert ($result.stderr | str contains 'completed edits were kept')
        assert not ($output | path exists)
        assert equal (contents $invalid) $after
        print 'PASS: all-failed updates and failed validation exit non-zero without an export'

        for release in [roc-invalid-tag roc-missing-arm64 roc-invalid-digest roc-missing-digest roc-duplicate-asset roc-invalid-json] {
            let work = ($scratch | path join $release)
            cp --recursive $baseline $work
            assert ((run-update $work [] '' $release).exit_code != 0)
            assert equal (open --raw ($work | path join packages/roc-nightly.nix)) $before.1.content
        }
        let roc_drift = ($scratch | path join roc-drift)
        cp --recursive $baseline $roc_drift
        $before.1.content | save --append ($roc_drift | path join packages/roc-nightly.nix)
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
        print 'PASS: invalid options and existing exports fail before mutation; staging files are cleaned'
    }
}
