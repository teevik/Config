{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    flake.homeModules.arch
  ];

  home.stateVersion = "24.11";
}
