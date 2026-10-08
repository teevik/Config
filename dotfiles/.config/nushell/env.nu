# Environment variables
$env.EDITOR = "nvim"
$env.PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig"

# Secrets from sops-nix, rendered by modules/nixos/standard/sops
source /etc/nushell/scripts/secrets.nu

# Add cargo bin and npm-packages to PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend [$"($nu.home-dir)/.cargo/bin" $"($nu.home-dir)/.npm-packages/bin"])

# Tool integrations
mkdir ~/.cache/carapace
$env.CARAPACE_BRIDGES = 'fish'
$env.CARAPACE_LENIENT = '1'
$env.INTELLI_SKIP_ESC_BIND = '1'
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
# wt config shell init nu | save --force ~/.cache/worktrunk-init.nu

plugin add /etc/nushell/plugins/skim

# nix-index command-not-found
$env.config.hooks.command_not_found = { |cmd_name|
    try {
        let attrs = (nix-locate --minimal --no-group --type x --type s --whole-name --at-root $"/bin/($cmd_name)")
        if ($attrs | is-empty) {
            null
        } else {
            let attrs = ($attrs | str trim | split row "\n" | each { |x| $x | str replace ".out" "" | str trim })
            $"(ansi $env.config.color_config.shape_external)($cmd_name)(ansi reset) may be found in the following packages:\n"
            + ($attrs | each { |x| $"  nix shell nixpkgs#($x)" } | str join "\n")
        }
    }
}
