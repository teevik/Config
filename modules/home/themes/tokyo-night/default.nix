{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.themes.tokyo-night;
  colors = config.teevik.theme.colors.withHashtag;
  nmConnectionEditor = lib.getExe pkgs.networkmanagerapplet;
  pulsemixer = lib.getExe pkgs.pulsemixer;
  light = lib.getExe pkgs.light;
in
{
  options.teevik.themes.tokyo-night = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tokyo-night theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.theme = {
      background = ./background.png;

      colors = {
        base00 = "#1A1B26";
        base01 = "#16161E";
        base02 = "#2F3549";
        base03 = "#444B6A";
        base04 = "#787C99";
        base05 = "#A9B1D6";
        base06 = "#CBCCD1";
        base07 = "#D5D6DB";
        base08 = "#C0CAF5";
        base09 = "#A9B1D6";
        base0A = "#0DB9D7";
        base0B = "#9ECE6A";
        base0C = "#B4F9F8";
        base0D = "#2AC3DE";
        base0E = "#BB9AF7";
        base0F = "#F7768E";
      };

      borderColor = "#F7768E";

      # gtkTheme = {
      #   name = "Catppuccin-Mocha-Standard-Pink-Dark";
      #   package = pkgs.catppuccin-gtk.override {
      #     accents = [ "pink" ];
      #     size = "standard";
      #     tweaks = [ "rimless" ];
      #     variant = "mocha";
      #   };
      # };

      gtkIconTheme = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
      };

      # neofetchImage = ./neofetch.png;

      discordTheme = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Dyzean/Tokyo-Night/main/themes/tokyo-night.theme.css";
        hash = "sha256-lWsU1A1NKfSkz73ieOJ0WAfVdCdw6YbsKsavJZnxkYA=";
      };

      spicetifyTheme = {
        theme = "Nightlight";
      };

      kittyTheme = "Tokyo Night";

      helixTheme = "tokyonight";
    };

    programs.waybar = mkIf config.teevik.desktop.waybar.enable {
      settings.mainBar = with colors; {
        # name = "main-bar";
        # id = "main-bar";
        layer = "top";

        height = 34;
        spacing = 0;
        margin = "0";
        # "margin-top": 0;
        # "margin-bottom": 0;
        # "margin-left": 0;
        # "margin-right": 0;
        fixed-center = true;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ ];
        modules-right = [ "pulseaudio" "backlight" "battery" "network" "clock" ];

        "backlight" = {
          interval = 2;
          format = "<span color='${base0F}'>{icon}</span> {percent}%";
          format-icons = [ "󰃞" "󰃝" "󰃟" "󰃠" ];

          on-scroll-up = "${light} -U 5%";
          on-scroll-down = "${light} -A 5%";
          smooth-scrolling-threshold = 1;
        };

        "battery" = {
          interval = 60;
          # bat = "BAT0";
          full-at = 100;
          design-capacity = false;
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "<span color='${base0F}'>{icon}</span> {capacity}%";
          format-charging = "<span color='${base0F}'>󰂄</span> {capacity}%";
          format-plugged = "<span color='${base0F}'>󰂄</span> {capacity}%";
          format-critical = "<span color='${base0F}'>{icon}</span> {capacity}%";
          format-full = "<span color='${base0F}'>󱟢</span> Full";
          format-alt = "<span color='${base0F}'>{icon}</span> {time}";
          format-time = "{H}h {M}min";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip = true;
          tooltip-format = "Usage: {power:0.1f}W";
        };

        "clock" = {
          interval = 60;
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
          format = "<span color='${base0F}'></span> {:%I:%M %p}";
          format-alt = "<span color='${base0F}'></span> {:%a %b %d, %G}";
        };

        "network" = {
          interval = 5;
          format-wifi = "<span color='${base0F}'>{icon}</span> {essid}";
          format-ethernet = "<span color='${base0F}'>󰈀</span> {ipaddr}/{cidr}";
          format-linked = "<span color='${base0F}'>󰈀</span> {ifname} (No IP)";
          format-disconnected = "<span color='${base0F}'></span> Disconnected";
          format-disabled = "<span color='${base0F}'></span> Disabled";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          tooltip-format = " {ifname} via {gwaddr}";
          on-click = "${nmConnectionEditor}";
        };

        "pulseaudio" = {
          format = "<span color='${base0F}'>{icon}</span> {volume}%";
          format-muted = "<span color='${base0F}'></span>  Mute";
          format-bluetooth = "<span color='${base0F}'>{icon}</span> {volume}%";
          format-bluetooth-muted = "<span color='${base0F}'></span>  Mute";
          format-icons = {
            default = [ "" "" "" ];
          };
          scroll-step = 5.0;
          on-click = "${pulsemixer} --toggle-mute";
          on-click-right = "${pulsemixer} --toggle-mute";
          smooth-scrolling-threshold = 1;
        };

        "wlr/workspaces" = {
          "sort-by-number" = true;
        };
      };

      style = import ./waybar-style.nix {
        inherit colors;
      };
    };
  };
}
