{ inputs, flake, ... }:
{
  imports = [
    inputs.nix-system-graphics.systemModules.default
    flake.modules.shared.packages
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;
}
