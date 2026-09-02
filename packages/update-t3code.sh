#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_file="$script_dir/t3code-nightly.nix"

read_version() {
  sed -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file"
}

old_version=$(read_version)

# nix-update must finish refreshing the source and fixed-output hashes before
# the local patch can be rebased onto the new upstream tag. Building here would
# try the old patch first and abort the update at exactly that point.
nix run github:Mic92/nix-update -- \
  --file "$script_dir/nix-update.nix" \
  --version unstable \
  --version-regex '^v([0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+)$' \
  --use-github-releases \
  --subpackage resourceMonitor \
  t3code-nightly

new_version=$(read_version)

if [[ "$old_version" != "$new_version" ]]; then
  printf 'Rebasing the T3 Code direnv patch: %s -> %s\n' "$old_version" "$new_version"
fi

bash "$script_dir/rebase-t3code-direnv-patch.sh" "$new_version"

nix build --no-link --print-build-logs --file "$script_dir/nix-update.nix" t3code-nightly
