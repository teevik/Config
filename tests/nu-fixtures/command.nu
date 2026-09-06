# Offline command double: never contacts a network or calls a real Nix daemon.
use std/assert

def --wrapped main [...raw_args] {
    # Nu parses bare CLI false/true/numbers as values in wrapped rest arguments.
    let args = ($raw_args | each { into string })
    {tool: $env.MOCK_TOOL, args: $args} | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
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
