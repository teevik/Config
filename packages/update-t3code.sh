#!/usr/bin/env bash
set -euo pipefail

build=true
if [[ "${1:-}" == --no-build ]]; then
  build=false
  shift
fi
if (( $# != 0 )); then
  echo "Usage: $0 [--no-build]" >&2
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

nix-update \
  --file "$script_dir/update-targets.nix" \
  --version unstable \
  --version-regex '^v([0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+)$' \
  --use-github-releases \
  --subpackage resourceMonitor \
  t3code-nightly

if "$build"; then
  nix build --no-link --print-build-logs --file "$script_dir/update-targets.nix" t3code-nightly
fi
