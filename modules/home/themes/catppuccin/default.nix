{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.themes.catppuccin;
  nmConnectionEditor = lib.getExe pkgs.networkmanagerapplet;
  pulsemixer = lib.getExe pkgs.pulsemixer;
  light = lib.getExe pkgs.light;
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
      # background = pkgs.fetchurl {
      #   url = "https://cdn.discordapp.com/attachments/1134581426323476520/1134581559777841403/wallpaper.jpg";
      #   sha256 = "a6HN4u+WtbxH/s6t0QL+FtCgjiirzJr+nk85OOf3Bxg=";
      # };
      background = ./background.png;

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
        name = "catppuccin-mocha-pink-standard+rimless";
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

      discordTheme =
        let
          discord-catppuccin = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "discord";
            rev = "c04f4bd43e571c19551e0e5da2d534408438564c";
            hash = "sha256-3uEVrR2T39Pj0puUwUPuUfXcCPoOq2lNHL8UpppTOiU=";
          };
        in
        "${discord-catppuccin}/themes/mocha.theme.css";

      spicetifyTheme = {
        # theme = "catppuccin";
        # colorScheme = "mocha";
        theme = "lucid";
        colorScheme = "catppuccin-mocha";
      };

      kittyTheme = "Catppuccin-Mocha";

      helixTheme = "catppuccin_mocha";
    };

    programs.waybar = mkIf config.teevik.desktop.waybar.enable {
      settings.mainBar = {
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
          format = "<span color='#e49186'>{icon}</span> {percent}%";
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
          format = "<span color='#b4a1db'>{icon}</span> {capacity}%";
          format-charging = "<span color='#b4a1db'>󰂄</span> {capacity}%";
          format-plugged = "<span color='#b4a1db'>󰂄</span> {capacity}%";
          format-critical = "<span color='#d66586'>{icon}</span> {capacity}%";
          format-full = "<span color='#b4a1db'>󱟢</span> Full";
          format-alt = "<span color='#b4a1db'>{icon}</span> {time}";
          format-time = "{H}h {M}min";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip = true;
          tooltip-format = "Usage: {power:0.1f}W";
        };

        "clock" = {
          interval = 60;
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
          format = "<span color='#9ee9ea'></span> {:%I:%M %p}";
          format-alt = "<span color='#9ee9ea'></span> {:%a %b %d, %G}";
        };

        "network" = {
          interval = 5;
          format-wifi = "<span color='#75dbe1'>{icon}</span> {essid}";
          format-ethernet = "<span color='#75dbe1'>󰈀</span> {ipaddr}/{cidr}";
          format-linked = "<span color='#75dbe1'>󰈀</span> {ifname} (No IP)";
          format-disconnected = "<span color='#df8293'></span> Disconnected";
          format-disabled = "<span color='#df8293'></span> Disabled";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          tooltip-format = " {ifname} via {gwaddr}";
          on-click = "${nmConnectionEditor}";
        };

        "pulseaudio" = {
          format = "<span color='#74dd91'>{icon}</span> {volume}%";
          format-muted = "<span color='#b4befe'></span>  Mute";
          format-bluetooth = "<span color='#75dbe1'>{icon}</span> {volume}%";
          format-bluetooth-muted = "<span color='#b4befe'></span>  Mute";
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

      style = ./waybar-style.css;
    };
  };
}
