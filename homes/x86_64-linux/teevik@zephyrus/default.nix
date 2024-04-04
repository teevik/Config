{ ... }:
{
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
      enableVrr = true;
      enableHidpi = true;
      scaling = 1.4;
    };
  };
}
