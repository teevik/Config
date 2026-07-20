# Environment variables
$env.EDITOR = "nvim"
$env.PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig"

# Secrets from sops-nix
if ("/run/secrets/mercury-ai-token" | path exists) {
    $env.MERCURY_AI_TOKEN = (open --raw /run/secrets/mercury-ai-token | str trim)
}

if ("/run/secrets/excalidraw-token" | path exists) {
    $env.EXCALIDRAW_TOKEN = (open --raw /run/secrets/excalidraw-token | str trim)
}

if ("/run/secrets/gemini-api-key" | path exists) {
    let gemini_api_key = (open --raw /run/secrets/gemini-api-key | str trim)
    if ($gemini_api_key | is-not-empty) {
        $env.GEMINI_API_KEY = $gemini_api_key
    }
}

if ("/run/secrets/brave-api-key" | path exists) {
    let brave_api_key = (open --raw /run/secrets/brave-api-key | str trim)
    if ($brave_api_key | is-not-empty) {
        $env.BRAVE_API_KEY = $brave_api_key
    }
}

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
