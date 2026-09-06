# Inspect entire closures; the original hook retains ownership of uploads and
# its daemon/socket. This name policy covers Marble/Astal, not arbitrary secrets.
def main [] {
    let original = $env.CACHIX_ORIGINAL_HOOK
    let nix_store = $env.NIX_STORE_BIN
    if ($original | is-empty) or ($nix_store | is-empty) {
        error make {msg: 'Absolute nix-store and original Cachix hook paths are required'}
    }
    if not ($original | str starts-with '/') or not ($nix_store | str starts-with '/') {
        error make {msg: 'Hook executable paths must be absolute'}
    }

    # Nix store paths cannot contain whitespace. Strings are not shell-expanded.
    let outputs = ($env.OUT_PATHS? | default '' | split row --regex '\s+' | where $it != '')
    mut safe = []
    for output in $outputs {
        # A missing executable and failed/empty queries all fail closed.
        let result = try {
            ^$nix_store --query --requisites $output | complete
        } catch {|err| {exit_code: 1, stdout: '', stderr: $err.msg} }
        if $result.exit_code != 0 {
            print --stderr $"cachix: skipping uninspectable closure: ($output)"
            continue
        }
        let closure = ($result.stdout | str trim | str downcase)
        if ($closure | is-empty) or $closure =~ 'marble|astal' {
            print --stderr $"cachix: keeping private closure local: ($output)"
            continue
        }
        $safe = ($safe | append $output)
    }
    if not ($safe | is-empty) {
        $env.OUT_PATHS = ($safe | str join ' ')
        exec $original
    }
}
