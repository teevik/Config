{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
  ];

  home.stateVersion = "25.11";
}
