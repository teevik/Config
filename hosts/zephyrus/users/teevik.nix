{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    # flake.homeModules.ctf
  ];

  home.stateVersion = "25.11";
}
