#!/usr/bin/env bash
set -euo pipefail

lint=$(realpath -- "$1")
fixtures=$(realpath -- "$2")
test_root=$(mktemp -d -t nix-lint-test.XXXXXX)
trap 'rm -rf -- "$test_root"' EXIT
cd -- "$test_root"
mkdir -p checks hosts/generated modules packages templates tests dotfiles
cp -- "$fixtures/clean.nix.txt" flake.nix
cp -- "$fixtures/clean.nix.txt" formatter.nix
# These files must not be scanned, even when they would fail to parse.
cp -- "$fixtures/parse-error.nix.txt" hosts/generated/hardware.nix
cp -- "$fixtures/parse-error.nix.txt" dotfiles/ignored.nix
"$lint" .

for fixture in repeated-keys unused-binding parse-error; do
  cp -- "$fixtures/$fixture.nix.txt" 'packages/new file.nix'
  chmod u+w 'packages/new file.nix'
  if "$lint" . > report.log 2>&1; then
    printf 'FAIL: lint accepted %s\n' "$fixture" >&2
    exit 1
  fi
  case "$fixture" in
    repeated-keys) expected='Avoid repeated keys' ;;
    unused-binding) expected='Unused let binding' ;;
    parse-error) expected='[Pp]arse|[Ss]yntax|unexpected|[Ee]xpected' ;;
  esac
  if ! grep -Eq "$expected" report.log; then
    cat report.log >&2
    printf 'FAIL: missing diagnostic for %s\n' "$fixture" >&2
    exit 1
  fi
  cmp -- "$fixtures/$fixture.nix.txt" 'packages/new file.nix'
  printf 'PASS: rejects %s without editing files\n' "$fixture"
done

cp -- "$fixtures/clean.nix.txt" 'packages/new file.nix'
"$lint" .
if "$lint" missing-root > report.log 2>&1; then
  echo 'FAIL: lint accepted a missing repository root' >&2
  exit 1
fi
