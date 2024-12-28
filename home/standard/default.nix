{ pkgs, ... }: {
  imports = [
    ./apps
    ./development
  ];

  programs.man.generateCaches = false;
}
