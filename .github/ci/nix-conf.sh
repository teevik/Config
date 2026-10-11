#!/usr/bin/env bash
# Print the runner's extra Nix configuration: nix.conf plus the trusted public
# keys the NixOS hosts use (homelab-cache.pub and trusted-public-keys.txt).
# With --github-output, append it to $GITHUB_OUTPUT as the `conf` output.
# With --public-only, drop the private cache from the substituters so an
# unreachable tailnet does not cost a download retry per store path.
set -euo pipefail

ci=$(dirname "${BASH_SOURCE[0]}")
minimal="$ci/../../modules/nixos/minimal"
to_github_output=false
public_only=false

for arg in "$@"; do
  case "$arg" in
    --github-output) to_github_output=true ;;
    --public-only) public_only=true ;;
    *) echo "usage: $0 [--github-output] [--public-only]" >&2; exit 2 ;;
  esac
done

conf() {
  local keys
  cat "$ci/nix.conf"
  if [[ "$public_only" == true ]]; then
    # A later assignment overrides the one in nix.conf.
    echo "substituters = https://cache.nixos.org"
  fi
  mapfile -t keys < <(sed '/^$/d' "$minimal/homelab-cache.pub" "$minimal/trusted-public-keys.txt")
  echo "trusted-public-keys = ${keys[*]}"
}

if [[ "$to_github_output" == true ]]; then
  {
    echo 'conf<<NIX_CONF_EOF'
    conf
    echo 'NIX_CONF_EOF'
  } >> "$GITHUB_OUTPUT"
else
  conf
fi
