{ pkgs, ... }:
{
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };

    services = {
      swayidle.enable = true;
    };

    desktop.hyprland = {
      enableHidpi = true;
      scaling = 1.5;
    };
  };

  home.packages = with pkgs; [
    jetbrains.clion
    jetbrains.rust-rover
  ];
}
