#!/usr/bin/env bash
set -euo pipefail

# The plugin's passthru Nix uses the exact headers/ABI it was compiled against.
# Select the runtime explicitly: Nix's default outputs also include its manual.
# Job-local output links protect cache hits against concurrent garbage collection.
nix_package=$(nix build '.#cargo-nix-plugin.nix^out' \
  --option plugin-files '' --out-link "$1.nix" --print-out-paths)
plugin_package=$(nix build '.#cargo-nix-plugin^out' \
  --option plugin-files '' --out-link "$1.plugin" --print-out-paths)
printf '%s\n' "$nix_package" "$plugin_package" > "$1"
