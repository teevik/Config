{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    # flake.homeModules.ctf
  ];

  teevik.hyprland = {
    enableVrr = true;
    enableHidpi = true;
    scaling = 1.333333;
  };
  wayland.windowManager.hyprland.settings.render.explicit_sync = 0;

  home.stateVersion = "25.05";
}
