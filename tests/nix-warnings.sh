#!/usr/bin/env bash
set -euo pipefail

# Exercise real toplevel evaluation, bypassing cached warning-free results.
# Ignore only the Git worktree notice; never suppress evaluation warnings.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
warning_log=$(mktemp -t nix-evaluation-warnings.XXXXXX)
trap 'rm -f -- "$warning_log"' EXIT

if (($# == 0)); then
  set -- zenbook
fi

status=0
for host in "$@"; do
  if ! nix eval --option eval-cache false --option warn-dirty false \
    --raw ".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" \
    > /dev/null 2> "$warning_log"; then
    cat -- "$warning_log" >&2
    printf 'FAIL: %s could not be evaluated\n' "$host" >&2
    status=1
    continue
  fi
  if rg --quiet '(^|[[:space:]])warning:' "$warning_log"; then
    cat -- "$warning_log" >&2
    printf 'FAIL: %s emitted evaluation warnings\n' "$host" >&2
    status=1
    continue
  fi
  printf 'PASS: %s evaluates without warnings\n' "$host"
done
exit "$status"
