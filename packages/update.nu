# Run child scripts with this same pinned interpreter, without personal config.
def main [] {
    cd ($env.FILE_PWD | path dirname)
    ^$nu.current-exe --no-config-file packages/update-opencode.nu
    # OMP's generated Bun dependencies and build patches live in llm-agents.nix.
    ^nix flake update llm-agents
    ^$nu.current-exe --no-config-file packages/update-t3code.nu --no-build
}
