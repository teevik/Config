{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    flake.homeModules.ctf
  ];

  programs.niri.settings.layout.preset-column-widths = [
    { proportion = 1.0; }
    { proportion = 1.0 / 2.0; }
  ];

  home.stateVersion = "24.11";
}
