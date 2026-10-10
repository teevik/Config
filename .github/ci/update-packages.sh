#!/usr/bin/env bash
# Update flake inputs and packages and export the result to the directory given
# as the first argument. build.py publishes the builds it runs to the private
# cache as they complete, even if the update fails.
set -euo pipefail

export_dir="$1"
# Resolve just from the same locked nixpkgs as this checkout.
nixpkgs_rev=$(jq -r '.nodes[.nodes[.root].inputs.nixpkgs].locked.rev' flake.lock)
python3 .github/ci/build.py updater "$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT" -- \
  nix shell "github:NixOS/nixpkgs/$nixpkgs_rev#just" \
  -c just update --export "$export_dir"
echo "Updated nixpkgs rev: $(jq -r '.nodes[.nodes[.root].inputs.nixpkgs].locked.rev' flake.lock)"
