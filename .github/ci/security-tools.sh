#!/usr/bin/env bash
# Build the pinned security scanner once per job and output its store path.
set -euo pipefail

out="$RUNNER_TEMP/security-tools"
build=(nix build --file packages/security/default.nix --out-link "$out")
if [[ "$PUBLISH_CACHE" == true ]]; then
  python3 .github/ci/build.py bootstrap "$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT" -- "${build[@]}"
else
  "${build[@]}"
fi
echo "package=$(readlink -f "$out")" >> "$GITHUB_OUTPUT"
