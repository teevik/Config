{ flake, ... }: {
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    flake.homeModules.ctf
  ];

  teevik.hyprland = {
    enableVrr = true;
    enableHidpi = true;
    scaling = 1.5;
  };

  home.stateVersion = "24.11";
}
