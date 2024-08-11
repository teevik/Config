{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.i3;
in
{
  options.teevik.desktop.i3 = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable i3
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rofi
    ];

    xsession = {
      enable = true;

      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;

        config = let mod = "Mod4"; in {
          modifier = mod;

          gaps = {
            inner = 12;
            outer = 5;
            smartGaps = true;
            smartBorders = "off";
          };

          keybindings = {
            "${mod}+w" = "exec firefox";
            "${mod}+Return" = "exec kitty";
            "${mod}+Shift+Return" = "exec kitty";
            "${mod}+d" = "exec rofi -show drun";
            "${mod}+f" = "exec nautilus";
            "${mod}+e" = "exec code";
            "${mod}+BackSpace" = "exec webcord";
            "${mod}+m" = "exec spotify";
            "${mod}+q" = "kill";
            "${mod}+Shift+q" = "exec poweroff";
            "${mod}+a" = "fullscreen toggle";
            "${mod}+space" = "floating toggle";
            "${mod}+1" = "workspace 1";
            "${mod}+2" = "workspace 2";
            "${mod}+3" = "workspace 3";
            "${mod}+4" = "workspace 4";
            "${mod}+5" = "workspace 5";
            "${mod}+6" = "workspace 6";
            "${mod}+7" = "workspace 7";
            "${mod}+8" = "workspace 8";
            "${mod}+9" = "workspace 9";
            "${mod}+0" = "workspace 10";
            "${mod}+Shift+1" = "move container to workspace 1";
            "${mod}+Shift+2" = "move container to workspace 2";
            "${mod}+Shift+3" = "move container to workspace 3";
            "${mod}+Shift+4" = "move container to workspace 4";
            "${mod}+Shift+5" = "move container to workspace 5";
            "${mod}+Shift+6" = "move container to workspace 6";
            "${mod}+Shift+7" = "move container to workspace 7";
            "${mod}+Shift+8" = "move container to workspace 8";
            "${mod}+Shift+9" = "move container to workspace 9";
            "${mod}+Shift+0" = "move container to workspace 10";
            "${mod}+left" = "focus left";
            "${mod}+right" = "focus right";
            "${mod}+up" = "focus up";
            "${mod}+down" = "focus down";
            "${mod}+Shift+left" = "move left";
            "${mod}+Shift+right" = "move right";
            "${mod}+Shift+up" = "move up";
            "${mod}+Shift+down" = "move down";
            "${mod}+Ctrl+left" = "resize shrink width 10 px or 10 ppt";
            "${mod}+Ctrl+right" = "resize grow width 10 px or 10 ppt";
            "${mod}+Ctrl+up" = "resize shrink height 10 px or 10 ppt";
            "${mod}+Ctrl+down" = "resize grow height 10 px or 10 ppt";
            "${mod}+mouse1" = "move";
            "${mod}+Shift+mouse1" = "resize";
            "${mod}+mouse4" = "--whole-window workspace next";
            "${mod}+mouse5" = "--whole-window workspace prev";
            "Ctrl+Mod1+Delete" = "exit";
            "XF86MonBrightnessUp" = "exec light -A 10";
            "XF86MonBrightnessDown" = "exec light -U 10";
            "XF86AudioRaiseVolume" = "exec pulsemixer --change-volume +10";
            "XF86AudioLowerVolume" = "exec pulsemixer --change-volume -10";
            "XF86AudioMute" = "exec pulsemixer --toggle-mute";
            "XF86AudioNext" = "exec playerctl next";
            "XF86AudioPrev" = "exec playerctl previous";
            "XF86AudioPlay" = "exec playerctl play-pause";
            "XF86AudioStop" = "exec playerctl stop";
          };
        };
      };
    };
  };
}
