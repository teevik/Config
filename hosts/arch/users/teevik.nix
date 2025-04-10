{ flake, ... }:
{
  imports = [
    flake.homeModules.minimal
    flake.homeModules.standard
    flake.homeModules.linux
    flake.homeModules.arch
  ];

  teevik.hyprland = {
    enableVrr = true;
    enableHidpi = true;
    scaling = 1.5;
  };

  home.stateVersion = "24.11";
}
