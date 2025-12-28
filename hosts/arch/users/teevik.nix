{ flake, ... }:
{
  imports = [
    flake.homeModules.minimal
    flake.homeModules.standard
    flake.homeModules.linux
    flake.homeModules.arch
  ];

  home.stateVersion = "24.11";
}
