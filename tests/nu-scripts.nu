use std/assert
use test-utils.nu [with-scratch assert-success fixture-hash t3-source t3-tags]

def main [source: path, probe: path] {
    let source = ($source | path expand)
    let probe = ($probe | path expand)
    let checker = ($source | path join packages/nu-scripts/check.nu)
    let warnings = ($source | path join tests/nix-warnings.nu)
    let scripts = ([packages scripts tests] | each {|directory| glob $"($source)/($directory)/**/*.nu" } | flatten)
    assert-success (^$nu.current-exe --no-config-file $checker ...$scripts | complete)

    with-scratch {|scratch|
        $env.MOCK_LOG = ($scratch | path join calls.jsonl)
        $env.MOCK_FAILURE = ''
        '' | save $env.MOCK_LOG

        # Syntax failures must fail the checker, not just print a false Boolean.
        'let broken = ' | save invalid.nu
        assert ((^$nu.current-exe --no-config-file $checker ($scratch | path join invalid.nu) | complete).exit_code != 0)
        'print "valid"' | save valid.nu
        assert-success (^$nu.current-exe --no-config-file $checker ($scratch | path join valid.nu) | complete)

        # Packaged scripts pin tools, safely pass arguments, and ignore user config.
        $env.XDG_CONFIG_HOME = ($scratch | path join user-config)
        mkdir ($env.XDG_CONFIG_HOME | path join nushell)
        'error make {msg: "Personal configuration must not run"}' | save ($env.XDG_CONFIG_HOME | path join nushell/env.nu)
        let result = (^$probe 'a space' --literal | complete)
        assert-success $result
        assert equal ($result.stdout | from json) ['a space' --literal]
        print 'PASS: pinned helper, runtime environment, arguments and syntax checking'

        let result = (^$nu.current-exe --no-config-file $warnings | complete)
        assert-success $result
        assert ($result.stdout =~ 'PASS: zenbook')
        let result = (^$nu.current-exe --no-config-file $warnings warning failed info | complete)
        assert equal $result.exit_code 1
        assert ($result.stderr =~ 'warning emitted evaluation warnings')
        assert ($result.stderr =~ 'failed could not be evaluated')
        assert ($result.stdout =~ 'PASS: info')
        print 'PASS: warning detection, failed evaluations and continued host coverage'

        # The T3 updater writes beside itself, so run a writable copy.
        let checkout = ($scratch | path join t3-checkout)
        mkdir $checkout
        cp --recursive ($source | path join packages) $checkout
        ^chmod -R u+w $checkout
        let t3code = ($checkout | path join packages/update-t3code.nu)
        let targets = ($checkout | path join packages/nu-scripts/update-targets.nix)
        let file = ($checkout | path join packages/t3code-nightly.nix)
        $env.MOCK_T3 = ($scratch | path join t3-fixture)
        let fetches = {|| open --raw $env.MOCK_LOG | lines | each { from json } | where tool == fetch | get args | flatten }
        let t3_run = {|...args|
            '' | save --force $env.MOCK_LOG
            ^$nu.current-exe --no-config-file $t3code ...$args | complete
        }
        let assert_declared = {|version lock licenses|
            let source = (open --raw $file)
            assert ($source | str contains $'version = "($version)";')
            assert ($source | str contains (fixture-hash $"src:($version)"))
            assert ($source | str contains (fixture-hash $"pnpmDeps:($lock)"))
            assert ($source | str contains (fixture-hash $"licenseNotices:($licenses)"))
        }

        # Newest by date and build, not tag order; stable releases are ignored.
        # The previous source is not in the store, so every input is refetched.
        t3-source $env.MOCK_T3 0.0.47-nightly.20261007.2701 'lock a' 'licenses a'
        $env.MOCK_TAGS = (t3-tags [v0.0.47 v0.0.47-nightly.20261007.2701 v0.0.47-nightly.20261006.2690 v0.0.46-nightly.20261005.2667])
        assert-success (do $t3_run '--no-build')
        do $assert_declared 0.0.47-nightly.20261007.2701 'lock a' 'licenses a'
        assert equal (do $fetches) [src pnpmDeps licenseNotices]
        let calls = (open --raw $env.MOCK_LOG | lines | each { from json } | where tool == nix)
        # Each corrected hash gets a confirming build, which reuses the output.
        let src = [build --no-link --keep-going --file $targets t3code-nightly.src]
        let dependencies = [build --no-link --keep-going --file $targets t3code-nightly.pnpmDeps t3code-nightly.licenseNotices]
        assert equal ($calls | where {|call| $call.args.0 == build } | get args) [$src $src $dependencies $dependencies]
        print 'PASS: T3 nightly selection and hash refresh from mismatch reports'

        # Only inputs whose source files changed get a placeholder and refetch.
        t3-source $env.MOCK_T3 0.0.47-nightly.20261008.2710 'lock a' 'licenses b'
        $env.MOCK_TAGS = (t3-tags [v0.0.47-nightly.20261008.2710 v0.0.47-nightly.20261007.2701])
        let result = (do $t3_run '--no-build')
        assert-success $result
        assert ($result.stdout =~ 'reusing: pnpmDeps')
        do $assert_declared 0.0.47-nightly.20261008.2710 'lock a' 'licenses b'
        assert equal (do $fetches) [src licenseNotices]

        let current = (open --raw $file)
        assert-success (do $t3_run '--no-build')
        assert equal (open --raw $file) $current
        assert equal (open --raw $env.MOCK_LOG | lines | each { from json } | get tool) [git nix]
        assert-success (do $t3_run)
        assert equal (open --raw $env.MOCK_LOG | lines | each { from json } | last | get args) [
            build --no-link --print-build-logs --file $targets t3code-nightly
        ]
        print 'PASS: T3 unchanged inputs are reused and current nightlies are left alone'

        t3-source $env.MOCK_T3 0.0.47-nightly.20261009.2720 'lock b' 'licenses b'
        $env.MOCK_TAGS = (t3-tags [v0.0.47-nightly.20261009.2720])
        $env.MOCK_FAILURE = 'fetch'
        assert ((do $t3_run '--no-build').exit_code != 0)
        assert equal (open --raw $file) $current
        for failure in [git nix] {
            $env.MOCK_FAILURE = $failure
            assert ((do $t3_run '--no-build').exit_code != 0)
            assert equal (open --raw $file) $current
        }
        assert equal (open --raw $env.MOCK_LOG | lines | each { from json } | get tool) [git nix]
        $env.MOCK_FAILURE = ''
        assert ((do $t3_run '--unknown').exit_code != 0)
        print 'PASS: T3 failures restore the definition, and unknown flags are rejected'

    }
}
