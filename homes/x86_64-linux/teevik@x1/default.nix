{ ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };

    services = {
      hypridle.enable = true;
    };

    desktop.hyprland = {
      monitor = {
        enable = true;
        resolution = "2560x1440";
        refreshRate = 60;
      };

      # enableHidpi = true;
      # scaling = 1.5;
    };
  };
}
