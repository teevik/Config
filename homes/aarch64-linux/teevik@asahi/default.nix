{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
    };

    apps = {
      home-manager.enable = true;
      linux.enable = true;
    };
  };

  home.packages = with pkgs; [
  ];
}
