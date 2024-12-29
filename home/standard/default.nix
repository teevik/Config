{ pkgs, ... }: {
  imports = [
    ./apps
    ./development
    ./shells
  ];

  programs.man.generateCaches = false;
}
