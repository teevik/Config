#!/usr/bin/env bash
# Remove preinstalled toolchains the Nix builds never use.
set -euo pipefail

echo "Disk space before cleanup:"
df -h /
sudo rm -rf \
  /usr/local/lib/android \
  /usr/local/share/boost \
  /usr/local/share/chromium \
  /usr/local/share/powershell \
  /usr/share/dotnet \
  /opt/az \
  /opt/ghc \
  /opt/hostedtoolcache/CodeQL
sudo docker image prune --all --force
echo "Disk space after cleanup:"
df -h /
