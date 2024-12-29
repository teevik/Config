{ pkgs, ... }: {
  imports = [
    ./apps
    ./development
    ./shells
  ];

  home.sessionVariables.EDITOR = "hx";
  programs.man.generateCaches = false;
}
