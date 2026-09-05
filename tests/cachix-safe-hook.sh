#!/usr/bin/env bash
# Closure-aware wrapper for the hook registered by cachix-action.
# Never call Cachix directly here: the original hook owns its daemon/socket.
set -euo pipefail

: "${CACHIX_ORIGINAL_HOOK:?original Cachix hook is required}"
: "${NIX_STORE_BIN:?absolute nix-store executable is required}"

# Store paths cannot contain whitespace. Disable glob expansion explicitly.
set -f
read -r -a outputs <<< "${OUT_PATHS:-}"
safe=()
for output in "${outputs[@]}"; do
  # A name filter on the root alone does not protect private dependencies.
  # Fail closed if the closure cannot be inspected (including GC races).
  if ! closure=$("$NIX_STORE_BIN" --query --requisites "$output"); then
    printf 'cachix: skipping uninspectable closure: %s\n' "$output" >&2
    continue
  fi
  if [[ -z $closure || ${closure,,} == *marble* || ${closure,,} == *astal* ]]; then
    printf 'cachix: keeping private closure local: %s\n' "$output" >&2
    continue
  fi
  safe+=("$output")
done

if ((${#safe[@]})); then
  export OUT_PATHS="${safe[*]}"
  exec "$CACHIX_ORIGINAL_HOOK"
fi
