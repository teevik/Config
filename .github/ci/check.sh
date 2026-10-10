#!/usr/bin/env bash
set -euo pipefail

generation="$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
prefix="$RUNNER_TEMP/flake-check"
# Determinate Nix creates GC roots for every successful check, including
# substituted outputs. The normal post-build hook only sees fresh builds.
check=(nix flake check --keep-going --print-build-logs --out-link "$prefix")
status=0
if [[ "$PUBLISH_CACHE" == true ]]; then
  python3 .github/ci/build.py bootstrap "$generation" -- "${check[@]}" || status=$?

  # Refresh retention even on a cache-only run or a failed unrelated check.
  manifest="$RUNNER_TEMP/flake-check-outputs.txt"
  python3 - "$prefix" "$manifest" <<'PY'
from pathlib import Path
import sys

prefix, manifest = map(Path, sys.argv[1:])
paths = sorted({str(path.resolve()) for path in prefix.parent.glob(prefix.name + "*")
                if path.is_symlink()})
manifest.write_text("".join(path + "\n" for path in paths))
PY
  python3 .github/ci/publish.py --dependencies bootstrap "$generation" "$manifest" || {
    if [[ "$status" == 0 ]]; then status=1; fi
  }
else
  "${check[@]}" || status=$?
fi
exit "$status"
