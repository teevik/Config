{ ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };

    desktop.hyprland = {
      enableVrr = true;

      monitor = {
        enable = true;
        resolution = "3440x1440";
        refreshRate = 175;
        # bitDepth = 10;
      };
    };
  };
}
