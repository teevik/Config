{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
  ];

  home.stateVersion = "24.11";
}
