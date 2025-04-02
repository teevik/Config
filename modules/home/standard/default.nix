{ ... }:
{
  imports = [
    ./apps
    ./development
    ./shells
    ./theme
    ./xdg.nix
  ];

  systemd.user.startServices = "sd-switch";
  home.sessionVariables.EDITOR = "hx";
  programs.man.generateCaches = false;
}
