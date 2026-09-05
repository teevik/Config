#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
guard=${1:-"$test_dir/cachix-safe-hook.sh"}
fixtures=${2:-"$test_dir/cachix-privacy-fixtures"}
scratch=$(mktemp -d -t cachix-privacy.XXXXXX)
trap 'status=$?; if ((status)) && [[ -f $scratch/guard.log ]]; then cat "$scratch/guard.log" >&2; fi; rm -rf -- "$scratch"' EXIT
cp -- "$fixtures/store.sh" "$fixtures/upload.sh" "$scratch/"
chmod u+x "$scratch/store.sh" "$scratch/upload.sh"
export NIX_STORE_BIN="$scratch/store.sh"
export CACHIX_ORIGINAL_HOOK="$scratch/upload.sh"
export UPLOAD_LOG="$scratch/uploads"
touch "$UPLOAD_LOG"

OUT_PATHS='/nix/store/test-safe /nix/store/test-marble /nix/store/test-wrapper /nix/store/test-astal-wrapper /nix/store/test-missing /nix/store/test-empty' \
  bash "$guard" 2> "$scratch/guard.log"
[[ $(< "$UPLOAD_LOG") == /nix/store/test-safe ]]
[[ $(wc -l < "$UPLOAD_LOG") == 1 ]]
OUT_PATHS='/nix/store/test-wrapper' bash "$guard" 2>> "$scratch/guard.log"
OUT_PATHS='' bash "$guard" 2>> "$scratch/guard.log"
[[ $(wc -l < "$UPLOAD_LOG") == 1 ]]
printf '%s\n' 'PASS: public closure forwarded; private roots, transitive private dependencies, failed queries, empty closures and empty batches blocked'
