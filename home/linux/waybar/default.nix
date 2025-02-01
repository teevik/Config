{ pkgs, lib, ... }:
let
  nmConnectionEditor = lib.getExe pkgs.networkmanagerapplet;
  pulsemixer = lib.getExe pkgs.pulsemixer;
  light = lib.getExe pkgs.light;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    style = ./style.css;

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
  };
}
