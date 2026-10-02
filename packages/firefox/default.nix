{
  pkgs,
}:

pkgs.firefox.override (import ./autoconfig.nix { inherit pkgs; })
