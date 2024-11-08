{ lib, ... }:
{
  home.stateVersion = "24.05";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
    };

    desktop = {
      hyprland = {
        enable = lib.mkForce false;
        enableHidpi = true;
        scaling = 1.5;
      };
    };

    services = {
      hypridle.enable = true;
    };
  };
}

