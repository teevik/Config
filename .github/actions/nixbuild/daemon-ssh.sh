#!/usr/bin/env bash
set -euo pipefail

: "${NIXBUILDNET_TOKEN:?Missing nixbuild token}"

# The daemon cannot use SendEnv for a token absent from its environment.
# Merge into the existing SetEnv: OpenSSH only uses the first such directive.
awk '
  /^[[:space:]]*SetEnv[[:space:]]/ {
    sub(/^[[:space:]]*SetEnv[[:space:]]+/, "SetEnv NIXBUILDNET_TOKEN=" ENVIRON["NIXBUILDNET_TOKEN"] " ")
    found = 1
  }
  { print }
  END { if (!found) exit 1 }
' "$1"
