{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
    };

    desktop.hyprland = {
      monitor = {
        enable = true;
        resolution = "3440x1440";
        refreshRate = 175;
        bitDepth = 10;
      };
    };
  };

  home.packages = with pkgs; [
    jetbrains.clion
  ];
}