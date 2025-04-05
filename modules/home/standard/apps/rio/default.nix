{ ... }:
{
  programs.rio = {
    enable = true;
  };

  xdg.configFile."rio/themes/catppucin-mocha.toml".source = ./catppuccin-mocha.toml;
}
