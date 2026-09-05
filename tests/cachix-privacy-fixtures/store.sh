#!/usr/bin/env bash
set -euo pipefail
[[ $1 == --query && $2 == --requisites ]]
case "$3" in
  /nix/store/test-safe)
    printf '%s\n' /nix/store/test-safe /nix/store/test-public-library ;;
  /nix/store/test-marble)
    printf '%s\n' /nix/store/test-marble ;;
  /nix/store/test-wrapper)
    printf '%s\n' /nix/store/test-wrapper /nix/store/test-middle /nix/store/test-marble ;;
  /nix/store/test-astal-wrapper)
    printf '%s\n' /nix/store/test-astal-wrapper /nix/store/test-astal ;;
  /nix/store/test-empty) ;;
  *) exit 1 ;;
esac
