#!/usr/bin/env bash
# Open one tracking issue for failed nightly runs, or comment on it if it is
# already open. Closing the issue starts a fresh one on the next failure.
set -euo pipefail

: "${GH_REPO:?}" "${GH_TOKEN:?}" "${RUN_URL:?}"
label=nightly-failure
title='Nightly update failed'
today=$(date -u +%Y-%m-%d)

# The label may not exist yet; creating it again fails, which is fine. A real
# problem (e.g. permissions) still surfaces when the issue is created below.
gh label create "$label" --color B60205 \
  --description 'The Nightly update workflow failed' >/dev/null 2>&1 || true

issue=$(
  gh issue list --state open --label "$label" --limit 100 --json number,title |
    jq -r --arg title "$title" 'map(select(.title == $title)) | min_by(.number) | .number // empty'
)

if [[ -n "$issue" ]]; then
  gh issue comment "$issue" --body "Failed again on $today: $RUN_URL"
else
  gh issue create --title "$title" --label "$label" --body "The Nightly update workflow failed on $today.

Run: $RUN_URL

Later failures are added as comments. Close this issue once the nightly passes again."
fi
