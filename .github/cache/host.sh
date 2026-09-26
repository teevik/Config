#!/usr/bin/env bash
set -euo pipefail

host=$1
case "$host" in
  desktop|zenbook) ;;
  *) echo "Unsupported host: $host" >&2; exit 2 ;;
esac

# Both nightly invocations use the same job, source cache and Nix store. Nix
# automatically reuses shared outputs when building the second host.
target=".#nixosConfigurations.${host}.config.system.build.toplevel"
system="$RUNNER_TEMP/nixos-$host"
build=(nix build --out-link "$system" --print-build-logs "$target")
echo "::group::Build $host"
if [[ "$PUBLISH_CACHE" == true ]]; then
  python3 .github/cache/build.py "$host" "$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT" -- "${build[@]}"
else
  "${build[@]}"
fi
echo '::endgroup::'

if [[ "$PUBLISH_CACHE" == true ]]; then
  echo "::group::Retain and verify $host"
  python3 .github/cache/publish.py "$host" "$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT" "$system"
  echo '::endgroup::'
fi

# Scanners need only public cache reads, never publication credentials.
unset NIX_CACHE_SSH_KEY NIX_CACHE_SIGNING_KEY NIX_CACHE_SSH_KEY_FILE NIX_CACHE_SIGNING_KEY_FILE

# Preserve the encrypted report even when the scanner reports an error.
echo 'scan-started=true' >> "$GITHUB_OUTPUT"
printf '\n## %s\n\n' "$host" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
"$SCANNER" "$target" --scope "$SCAN_SCOPE" --output "$RUNNER_TEMP/security-$host"
