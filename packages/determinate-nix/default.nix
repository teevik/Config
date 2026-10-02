{ inputs, perSystem, ... }:
# Determinate Nix with unmerged upstream PRs
perSystem.determinate-nix.default.appendPatches [
  inputs.determinate-nix-pr-572
  ./slop-optimizations.patch
]
