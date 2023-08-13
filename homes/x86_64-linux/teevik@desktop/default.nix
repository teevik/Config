{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      hyprland.enable = true;
    };
  };

  home.packages = with pkgs; [
    jetbrains.clion
  ];
}
