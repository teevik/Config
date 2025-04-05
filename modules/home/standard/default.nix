{ ... }:
{
  imports = [
    ./apps
    ./development
    ./shells
    ./theme
    ./xdg.nix
  ];

  home.sessionVariables.EDITOR = "hx";
}
