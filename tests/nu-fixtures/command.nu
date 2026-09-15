# Offline command double: never contacts a network or calls a real Nix daemon.
use std/assert

# Model command effects in a writable checkout; production update scripts still
# perform their real fetching, parsing, replacement, sequencing, and export.
def update-command [tool: string, args: list<string>] {
    let failure = ($env.MOCK_FAILURE? | default '')
    let release_mode = ($env.MOCK_RELEASE? | default 'valid')
    if $failure == $tool and $tool != 'nix-update' { exit 17 }
    match $tool {
        'nix' => {
            if $args == [flake update] {
                if $failure == 'flake' { exit 17 }
                {fixture: updated} | to json | save --force flake.lock
            } else if $args.0 == 'build' {
                assert (open --raw packages/opencode.nix | str contains '1.2.3-beta-fixture')
                assert (open --raw packages/t3code-nightly.nix | str contains '# fixture: t3 source refreshed')
                assert equal (open --raw flake.lock | from json).fixture updated
                if $failure == 'build' { exit 17 }
            } else { error make {msg: $"Unexpected Nix command: ($args)"} }
        }
        'nix-update' => {
            let file = 'packages/t3code-nightly.nix'
            if not (open --raw $file | str contains '# fixture: t3 source refreshed') {
                "\n# fixture: t3 source refreshed\n" | save --append $file
            }
            if $failure == 'nix-update' { exit 17 }
        }
        'npm' => {
            if $args.2 == 'version' {
                print '1.2.3-beta-fixture'
            } else {
                if $release_mode == 'invalid-integrity' { print invalid; return }
                let arch = if ($args.1 | str contains x64) { 'x64' } else { 'arm64' }
                print ('sha256-' + ($arch | hash sha256 --binary | encode base64))
            }
        }
        'curl' => {
            assert equal ($args | last) 'https://api.github.com/repos/anomalyco/opencode-beta/releases/tags/v1.2.3-beta-fixture'
            if $release_mode == 'invalid-json' { print 'not JSON'; return }
            mut release = {
                tag_name: v1.2.3-beta-fixture
                assets: [
                    {name: opencode-desktop-linux-x86_64.AppImage, digest: ('sha256:' + ('x64' | hash sha256))}
                    {name: opencode-desktop-linux-arm64.AppImage, digest: ('sha256:' + ('arm64' | hash sha256))}
                ]
            }
            if $release_mode == 'mismatch' { $release = ($release | update tag_name v0.0.0) }
            if $release_mode == 'missing-assets' { $release = ($release | update assets []) }
            if $release_mode == 'invalid-digest' { $release = ($release | update assets.0.digest 'sha256:bad') }
            if $release_mode == 'missing-digest' { $release = ($release | reject assets.0.digest) }
            $release | to json | print
        }
        _ => { error make {msg: $"Unexpected update tool: ($tool)"} }
    }
}

def --wrapped main [...raw_args] {
    # Nu parses bare CLI false/true/numbers as values in wrapped rest arguments.
    let args = ($raw_args | each { into string })
    {tool: $env.MOCK_TOOL, args: $args} | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
    if ($env.MOCK_UPDATE_WORKFLOW? | default '') == '1' {
        update-command $env.MOCK_TOOL $args
        return
    }
    if ($env.MOCK_FAILURE? | default '') == $env.MOCK_TOOL { exit 17 }

    if $env.MOCK_TOOL == 'nix' and $args.0 == 'eval' {
        let prefix = [eval --option eval-cache 'false' --option warn-dirty 'false' --abort-on-warn --show-trace --raw]
        assert equal ($args | drop 1) $prefix
        let target = ($args | last)
        if $target =~ '\.warning\.' { print --stderr 'evaluation warning: fixture' }
        if $target =~ '\.failed\.' { print --stderr 'evaluation failed: fixture'; exit 23 }
        if $target =~ '\.info\.' { print --stderr 'informational trace: fixture' }
        print '/nix/store/fixture-system.drv'
    }
}
