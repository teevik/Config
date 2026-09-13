use std/assert
use test-utils.nu [with-scratch assert-success]
use ../packages/update-opencode.nu [prepare-update write-update]

def main [source: path, probe: path] {
    let source = ($source | path expand)
    let probe = ($probe | path expand)
    let checker = ($source | path join packages/nu-scripts/check.nu)
    let warnings = ($source | path join tests/nix-warnings.nu)
    let t3code = ($source | path join packages/update-t3code.nu)
    let opencode = ($source | path join packages/update-opencode.nu)
    let scripts = (glob $"($source)/packages/**/*.nu" | append (glob $"($source)/tests/**/*.nu"))
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

        '' | save --force $env.MOCK_LOG
        assert-success (^$nu.current-exe --no-config-file $t3code --no-build | complete)
        let calls = (open --raw $env.MOCK_LOG | lines | each { from json })
        assert equal $calls.tool [nix-update]
        assert equal $calls.0.args [
            --file ($source | path join packages/update-targets.nix)
            --version unstable
            --version-regex '^v([0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+)$'
            --use-github-releases --subpackage resourceMonitor --subpackage licenseNotices t3code-nightly
        ]
        '' | save --force $env.MOCK_LOG
        assert-success (^$nu.current-exe --no-config-file $t3code | complete)
        let calls = (open --raw $env.MOCK_LOG | lines | each { from json })
        assert equal $calls.tool [nix-update nix]
        assert equal $calls.1.args [build --no-link --print-build-logs --file ($source | path join packages/update-targets.nix) t3code-nightly]

        '' | save --force $env.MOCK_LOG
        $env.MOCK_FAILURE = 'nix-update'
        assert ((^$nu.current-exe --no-config-file $t3code | complete).exit_code != 0)
        assert equal (open --raw $env.MOCK_LOG | lines | each { from json } | get tool) [nix-update]
        $env.MOCK_FAILURE = 'nix'
        assert ((^$nu.current-exe --no-config-file $t3code | complete).exit_code != 0)
        $env.MOCK_FAILURE = ''
        assert ((^$nu.current-exe --no-config-file $t3code --unknown | complete).exit_code != 0)
        print 'PASS: T3 update flags, no-build mode, and failure propagation'

        let sources = {
            cli: (open --raw ($source | path join packages/opencode.nix))
            desktop: (open --raw ($source | path join packages/opencode-desktop.nix))
        }
        let version = '1.2.3-beta-fixture'
        let integrities = {
            cli-linux-x64-baseline: ('sha256-' + ('x64' | hash sha256 --binary | encode base64))
            cli-linux-arm64: ('sha256-' + ('arm64' | hash sha256 --binary | encode base64))
        }
        let release = {
            tag_name: $"v($version)"
            assets: [
                {name: opencode-desktop-linux-x86_64.AppImage, digest: ('sha256:' + ('x64' | hash sha256))}
                {name: opencode-desktop-linux-arm64.AppImage, digest: ('sha256:' + ('arm64' | hash sha256))}
            ]
        }
        let updated = (prepare-update $sources $version $integrities $release)
        assert ($updated.cli | str contains $'version = "($version)";')
        for integrity in ($integrities | values) { assert ($updated.cli | str contains $integrity) }
        for arch in [x64 arm64] {
            assert ($updated.desktop | str contains ('sha256-' + ($arch | hash sha256 --binary | encode base64)))
        }
        assert equal (prepare-update $updated $version $integrities $release) $updated

        assert error { prepare-update $sources $version $integrities ($release | update tag_name v0.0.0) }
        assert error { prepare-update $sources $version $integrities ($release | update assets []) }
        assert error { prepare-update $sources $version $integrities ($release | update assets.0.digest 'sha256:bad') }
        assert error { prepare-update $sources $version $integrities ($release | reject assets.0.digest) }
        assert error { prepare-update $sources $version ($integrities | update cli-linux-arm64 invalid) $release }
        assert error { prepare-update ($sources | update cli ($sources.cli + $sources.cli)) $version $integrities $release }

        mkdir packages
        $sources.cli | save packages/opencode.nix
        $sources.desktop | save packages/opencode-desktop.nix
        ^chmod 640 packages/opencode.nix
        ^chmod 644 packages/opencode-desktop.nix
        write-update ($scratch | path join packages) $updated
        assert equal (open --raw packages/opencode.nix) $updated.cli
        assert equal (open --raw packages/opencode-desktop.nix) $updated.desktop
        assert equal (glob packages/* | length) 2
        assert equal (^stat --format=%a packages/opencode.nix | str trim) '640'
        assert equal (^stat --format=%a packages/opencode-desktop.nix | str trim) '644'

        # A failed first fetch must not get as far as HTTP or changing files.
        $env.MOCK_FAILURE = 'npm'
        assert ((^$nu.current-exe --no-config-file $opencode | complete).exit_code != 0)
        assert equal (open --raw ($source | path join packages/opencode.nix)) $sources.cli
        assert equal (open --raw ($source | path join packages/opencode-desktop.nix)) $sources.desktop
        print 'PASS: OpenCode rendering, digests, version/layout failures, atomic file replacement and failed fetch'
    }
}
