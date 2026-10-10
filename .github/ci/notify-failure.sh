#!/usr/bin/env bash
# Open one tracking issue for failed nightly runs, or comment on it if it is
# already open. Closing the issue starts a fresh one on the next failure.
# FAILED_UPDATES names package updates that failed while the rest of the night
# succeeded; without it the whole run failed.
set -euo pipefail

: "${GH_REPO:?}" "${GH_TOKEN:?}" "${RUN_URL:?}"
label=nightly-failure
title='Nightly update failed'
today=$(date -u +%Y-%m-%d)
if [[ -n "${FAILED_UPDATES:-}" ]]; then
  what="These package updates failed and were left out: $FAILED_UPDATES. The rest of the nightly succeeded."
else
  what="The Nightly update workflow failed."
fi

# The label may not exist yet; creating it again fails, which is fine. A real
# problem (e.g. permissions) still surfaces when the issue is created below.
gh label create "$label" --color B60205 \
  --description 'The Nightly update workflow failed' >/dev/null 2>&1 || true

issue=$(
  gh issue list --state open --label "$label" --limit 100 --json number,title |
    jq -r --arg title "$title" 'map(select(.title == $title)) | min_by(.number) | .number // empty'
)

if [[ -n "$issue" ]]; then
  gh issue comment "$issue" --body "$today: $what

Run: $RUN_URL"
else
  gh issue create --title "$title" --label "$label" --body "$today: $what

Run: $RUN_URL

Later failures are added as comments. Close this issue once the nightly passes again."
fi
