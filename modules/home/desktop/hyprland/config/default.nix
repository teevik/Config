{ osConfig, lib, config, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.hyprland;

  theme = config.teevik.theme;
in
{
  options.teevik.desktop.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hyprland
      '';
    };

    enableVrr = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable vrr
      '';
    };

    enableHidpi = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable scaling
      '';
    };

    scaling = mkOption {
      type = types.float;
      default = 1.;
        description = ''
        Amount to scale
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      teevik.hyprland-scratchpad
      pkgs.catppuccin-cursors.mochaDark
    ];

    home.sessionVariables.XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    home.sessionVariables.HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";

    wayland.windowManager.hyprland = {
      enable = true;

      package = osConfig.programs.hyprland.package;

      settings = {
        exec-once = [
          "systemctl restart --user waybar.service swaybg.service"
          "1password"
        ];

        misc = {
          # enable_swallow = true;
          # swallow_regex = "^(kitty)$";
          focus_on_activate = true;
          animate_manual_resizes = true;
          close_special_on_empty = false;
          new_window_takes_over_fullscreen = 2;
          middle_click_paste = false;
        };


        input = {
          kb_layout = "us,no";
          kb_options = "grp:alt_shift_toggle,caps:escape";

          follow_mouse = 1;
          natural_scroll = false;

          touchpad = {
            natural_scroll = true;
            disable_while_typing = false;
          };

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        device = {
          name = "logitech-usb-receiver";
          sensitivity = 0.75;
        };

        gestures = {
          workspace_swipe = true;
        };

        general = {
          layout = "dwindle";

          gaps_in = 8;
          gaps_out = 12;
          border_size = 2;

          "col.active_border" = "rgb(${theme.borderColor})";
          "col.inactive_border" = "rgba(${theme.borderColor}30)";
        };

        dwindle = {
          # TODO could be true?
          preserve_split = true;
          smart_split = true;
        };

        decoration = {
          rounding = 4;

          dim_inactive = true;
          dim_strength = 0;
          dim_special = 0.5;

          drop_shadow = true;
          shadow_offset = "0 5";
          shadow_range = 50;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1a1a)";

          blur = {
            enabled = true;
            size = 10;
            passes = 3;
            new_optimizations = true;
            xray = true;
            special = true;
          };
        };

        bezier = [ "default, 0.05, 0.9, 0.1, 1.05" ];

        animation = [
          "windows, 1, 7, default"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };
}
