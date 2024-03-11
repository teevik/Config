{ ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
    };

    desktop.hyprland = {
      monitor = {
        enable = true;
        resolution = "2560x1440";
        refreshRate = 60;
      };
    };
  };
}
