{
  inputs,
  pkgs,
  system,
  ...
}:
import ./cargo-nix.nix { inherit inputs pkgs system; }
