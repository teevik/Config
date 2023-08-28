{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
    };

    desktop = {
      hyprland = {
        enableHidpi = true;
        scaling = 1.5;
      };
    };

    apps = {
      home-manager.enable = true;
    };
  };

  home.packages = with pkgs; [
  ];
}
