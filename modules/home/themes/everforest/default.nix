{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.themes.everforest;
in
{
  options.teevik.themes.everforest = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable everforest theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.theme = {
      background = pkgs.fetchurl {
        url = "https://cdn.discordapp.com/attachments/1134581426323476520/1134972522505437295/death-stranding-upscayl.png";
        sha256 = "pjzV0HoYGkkzBYYf9g74QsyUSWLH4KWppp+1WfKTmN4=";
      };

      colors = {
        base00 = "#2f383e"; # bg0,       palette1 dark (medium)
        base01 = "#374247"; # bg1,       palette1 dark (medium)
        base02 = "#4a555b"; # bg3,       palette1 dark (medium)
        base03 = "#859289"; # grey1,     palette2 dark
        base04 = "#9da9a0"; # grey2,     palette2 dark
        base05 = "#d3c6aa"; # fg,        palette2 dark
        base06 = "#e4e1cd"; # bg3,       palette1 light (medium)
        base07 = "#fdf6e3"; # bg0,       palette1 light (medium)
        base08 = "#7fbbb3"; # blue,      palette2 dark
        base09 = "#d699b6"; # purple,    palette2 dark
        base0A = "#dbbc7f"; # yellow,    palette2 dark
        base0B = "#83c092"; # aqua,      palette2 dark
        base0C = "#e69875"; # orange,    palette2 dark
        base0D = "#a7c080"; # green,     palette2 dark
        base0E = "#e67e80"; # red,       palette2 dark
        base0F = "#eaedc8"; # bg_visual, palette1 dark (medium)
      };

      # name: 'Everforest Dark'

      # color_01: '#4B565C'    # Black (Host)
      # color_02: '#E67E80'    # Red (Syntax string)
      # color_03: '#A7C080'    # Green (Command)
      # color_04: '#DBBC7F'    # Yellow (Command second)
      # color_05: '#7FBBB3'    # Blue (Path)
      # color_06: '#D699B6'    # Magenta (Syntax var)
      # color_07: '#83C092'    # Cyan (Prompt)
      # color_08: '#D3C6AA'    # White

      # color_09: '#5C6A72'    # Bright Black
      # color_10: '#F85552'    # Bright Red (Command error)
      # color_11: '#8DA101'    # Bright Green (Exec)
      # color_12: '#DFA000'    # Bright Yellow
      # color_13: '#3A94C5'    # Bright Blue (Folder)
      # color_14: '#DF69BA'    # Bright Magenta
      # color_15: '#35A77C'    # Bright Cyan
      # color_16: '#DFDDC8'    # Bright White

      # background: '#2D353B'  # Background
      # foreground: '#D3C6AA'  # Foreground (Text)

      # cursor: '#D3C6AA'      # Cursor

      borderColor = "#a7c080";

      gtkTheme = {
        name = "Everforest-Dark-BL";
        package = pkgs.teevik.everforest-gtk-theme;
      };

      gtkIconTheme = {
        name = "Everforest-Dark";
        package = pkgs.teevik.everforest-gtk-theme;
      };

      neofetchImage = ./neofetch.png;

      discordTheme = ./discord-theme.css;

      spicetifyTheme = {
        colorScheme = "custom";

        customColorScheme = {
          text = "D3C6AA";
          subtext = "D3C6AA";
          accent = "E5C890";
          main = "2B3339";
          sidebar = "2B3339";
          player = "2B3339";
          card = "2B3339";
          shadow = "292C3C";
          selected-row = "626880";
          button = "D3C6AA";
          button-active = "949CBB";
          button-disabled = "737994";
          tab-active = "414559";
          notification = "414559";
          notification-error = "E78284";
          equalizer = "F2D5CF";
          misc = "626880";
        };
      };

      kittyTheme = "everforest_dark_medium";

      helixTheme = "everforest_dark";
    };
  };
}
