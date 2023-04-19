{ inputs, ... }:
{
  config = {
    home = {
      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings = {
          # name = "main-bar";
          # id = "main-bar";
          layer = "top";

          height = 34;
          spacing = 0;
          margin = 0;
          # "margin-top": 0;
          # "margin-bottom": 0;
          # "margin-left": 0;
          # "margin-right": 0;
          fixed-center = true;
          modules-left = [ "wlr/workspaces" ];
          modules-center = [];
          modules-right = [ "pulseaudio" "backlight" "battery" "network" "clock" ];
        };

        style = ./style.css;
      };
    };
  };
} 