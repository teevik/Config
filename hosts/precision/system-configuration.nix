{ flake, ... }:
{
  imports = [
    flake.modules.shared.packages
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };
}
