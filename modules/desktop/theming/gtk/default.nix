{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.theming.gtk;
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
    environment.sessionVariables.XCURSOR_THEME = "Catppuccin-Mocha-Dark-Cursors";

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
  };
}
