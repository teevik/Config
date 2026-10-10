#!/usr/bin/env bash
# Print the runner's extra Nix configuration: nix.conf plus the trusted public
# keys the NixOS hosts use (homelab-cache.pub and trusted-public-keys.txt).
# With --github-output, append it to $GITHUB_OUTPUT as the `conf` output.
set -euo pipefail

ci=$(dirname "${BASH_SOURCE[0]}")
minimal="$ci/../../modules/nixos/minimal"

conf() {
  local keys
  cat "$ci/nix.conf"
  mapfile -t keys < <(sed '/^$/d' "$minimal/homelab-cache.pub" "$minimal/trusted-public-keys.txt")
  echo "trusted-public-keys = ${keys[*]}"
}

case "${1:-}" in
  "") conf ;;
  --github-output)
    {
      echo 'conf<<NIX_CONF_EOF'
      conf
      echo 'NIX_CONF_EOF'
    } >> "$GITHUB_OUTPUT"
    ;;
  *) echo "usage: $0 [--github-output]" >&2; exit 2 ;;
esac
