{ ... }:
{
  imports = [
    ./apps
    ./development
    ./shells
    ./themes
    ./xdg.nix
  ];

  home.sessionVariables.EDITOR = "hx";
}
