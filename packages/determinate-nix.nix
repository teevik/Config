{ inputs, perSystem, ... }:
# Determinate Nix with unmerged upstream PRs. Drop a patch when it stops
# applying: that means the PR has been merged.
perSystem.determinate-nix.default.appendPatches [
  # Parallel derivationStrict dependency traversal.
  inputs.determinate-nix-pr-572
]
