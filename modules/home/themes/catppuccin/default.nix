{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.themes.catppuccin;
in
{
  options.teevik.themes.catppuccin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable catppuccin theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.theme = {
      background = pkgs.fetchurl {
        url = "https://cdn.discordapp.com/attachments/1134581426323476520/1134581559777841403/wallpaper.jpg";
        sha256 = "a6HN4u+WtbxH/s6t0QL+FtCgjiirzJr+nk85OOf3Bxg=";
      };

      colors = {
        base00 = "#1e1e2e"; # base
        base01 = "#181825"; # mantle
        base02 = "#313244"; # surface0
        base03 = "#45475a"; # surface1
        base04 = "#585b70"; # surface2
        base05 = "#cdd6f4"; # text
        base06 = "#f5e0dc"; # rosewater
        base07 = "#b4befe"; # lavender
        base08 = "#f38ba8"; # red
        base09 = "#fab387"; # peach
        base0A = "#f9e2af"; # yellow
        base0B = "#a6e3a1"; # green
        base0C = "#94e2d5"; # teal
        base0D = "#89b4fa"; # blue
        base0E = "#cba6f7"; # mauve
        base0F = "#f2cdcd"; # flamingo
      };

      borderColor = "#cba6f7";

      gtkTheme = {
        name = "Catppuccin-Mocha-Standard-Pink-dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "standard";
          tweaks = [ "rimless" ];
          variant = "mocha";
        };
      };

      gtkIconTheme = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
      };

      neofetchImage = ./neofetch.png;

      vscodeTheme = "Catppuccin Frappé";

      discordTheme =
        let
          discord-catppuccin = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "discord";
            rev = "c04f4bd43e571c19551e0e5da2d534408438564c";
            hash = "sha256-3uEVrR2T39Pj0puUwUPuUfXcCPoOq2lNHL8UpppTOiU=";
          };
        in
        "${discord-catppuccin}/themes/frappe.theme.css";
    };
  };
}
