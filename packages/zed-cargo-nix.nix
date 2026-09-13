{
  inputs,
  pkgs,
  system,
  ...
}:
# Compatibility alias for the initial cargo-nix package.
import ./zed { inherit inputs pkgs system; }
