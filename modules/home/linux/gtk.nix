{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (config.teevik.theme) gtkTheme gtkIconTheme;
in
{
  home.packages = [
    pkgs.catppuccin-cursors.mochaDark
  ];

  gtk = {
    enable = true;

    cursorTheme = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };

    theme =
      if gtkTheme != null then
        gtkTheme
      else
        {
          package = pkgs.adw-gtk3;
          name = "adw-gtk3-dark";
        };

    iconTheme =
      if gtkIconTheme != null then
        gtkIconTheme
      else
        {
          name = "MoreWaita";
          package = pkgs.morewaita-icon-theme;
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
}
