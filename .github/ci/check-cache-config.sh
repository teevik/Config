#!/usr/bin/env bash
# Fail early when the private cache cannot be reached or published to.
set -euo pipefail

test -n "$CACHE_CLIENT_ID" && test -n "$CACHE_AUDIENCE"
test "$CACHE_POLICY_READY" = true
if [[ "$PUBLISH_CACHE" == true ]]; then
  test -n "$NIX_CACHE_SSH_KEY" && test -n "$NIX_CACHE_SIGNING_KEY"
fi
