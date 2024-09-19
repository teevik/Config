{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.theming.gtk;
  inherit (config.teevik.theme) gtkTheme gtkIconTheme;
in
{
  options.teevik.desktop.theming.gtk = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gtk theming
      '';
    };
  };

  config = mkIf cfg.enable {
    gtk = {
      enable = true;

      cursorTheme = {
        name = "catppuccin-mocha-dark-cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      theme = if gtkTheme != null then gtkTheme else {
        package = pkgs.adw-gtk3;
        name = "adw-gtk3-dark";
      };

      iconTheme = if gtkIconTheme != null then gtkIconTheme else {
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
