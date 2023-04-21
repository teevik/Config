{ pkgs, ... }:
{
  config.home = {
    gtk = {
      enable = true;

      cursorTheme = {
        name = "Catppuccin-Mocha-Dark-Cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      theme = {
        name = "Catppuccin-Mocha-Standard-Pink-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "standard";
          tweaks = [ "rimless" ];
          variant = "mocha";
        };
      };
    };
  };
}