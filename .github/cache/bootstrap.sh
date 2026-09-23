#!/usr/bin/env bash
set -euo pipefail

# The plugin's passthru Nix uses the exact headers/ABI it was compiled against.
nix_package=$(nix build .#cargo-nix-plugin.nix \
  --option plugin-files '' --no-link --print-out-paths)
plugin_package=$(nix build .#cargo-nix-plugin \
  --option plugin-files '' --no-link --print-out-paths)
printf '%s\n' "$nix_package" "$plugin_package" > "$1"
