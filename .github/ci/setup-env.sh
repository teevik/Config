#!/usr/bin/env bash
# Log the locked nixpkgs revision and export the cache settings that host.sh,
# check.sh and publish.py read in later steps of the job.
set -euo pipefail

case "$PUBLISH_CACHE" in
  true|false) ;;
  *) echo "::error::publish-cache must be true or false, got: $PUBLISH_CACHE"; exit 2 ;;
esac
echo "nixpkgs rev: $(jq -r '.nodes[.nodes[.root].inputs.nixpkgs].locked.rev' flake.lock)"
{
  echo "NIX_CACHE_VERIFIED_PATHS=$RUNNER_TEMP/nix-cache-verified-paths.json"
  echo "PUBLISH_CACHE=$PUBLISH_CACHE"
} >> "$GITHUB_ENV"
