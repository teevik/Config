{
  perSystem,
  pkgs,
  ...
}:
pkgs.nix-update.override {
  nix = perSystem.determinate-nix.default;
}
