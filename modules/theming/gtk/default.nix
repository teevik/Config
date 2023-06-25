{ pkgs, ... }:
{
  teevik.home = {
    gtk = {
      enable = true;

      cursorTheme = {
        name = "Catppuccin-Mocha-Dark-Cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      theme = {
        name = "Catppuccin-Mocha-Standard-Pink-dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "standard";
          tweaks = [ "rimless" ];
          variant = "mocha";
        };
      };

      iconTheme = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
