# Environment variables
$env.EDITOR = "hx"
$env.PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig"

# Add cargo bin and npm-packages to PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend [$"($nu.home-dir)/.cargo/bin" $"($nu.home-dir)/.npm-packages/bin"])

# Tool integrations
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
zoxide init nushell | save --force ~/.cache/zoxide.nu

# nix-index command-not-found
$env.config.hooks.command_not_found = { |cmd_name|
    try {
        let attrs = (nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root $"/bin/($cmd_name)")
        if ($attrs | is-empty) {
            null
        } else {
            let attrs = ($attrs | str trim | split row "\n" | each { |x| $x | str replace ".out" "" | str trim })
            $"(ansi $env.config.color_config.shape_external)($cmd_name)(ansi reset) may be found in the following packages:\n"
            + ($attrs | each { |x| $"  nix shell nixpkgs#($x)" } | str join "\n")
        }
    }
}
