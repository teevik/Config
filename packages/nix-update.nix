{
  perSystem,
  pkgs,
  ...
}:
pkgs.nix-update.override {
  nix = perSystem.self.determinate-nix;
}
