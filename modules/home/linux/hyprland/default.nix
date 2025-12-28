{
  inputs,
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.teevik.theme) borderColor cursorTheme;
  enabled = osConfig.programs.hyprland.enable;
in
{
  imports = [
    ./keybinds.nix
    ./windowrules.nix

    inputs.automatic-sunset.homeModules.default
  ];

  config = mkIf enabled {
    home.packages = [
      cursorTheme.package
    ];

    home.sessionVariables = {
      XCURSOR_THEME = cursorTheme.name;
      HYPRCURSOR_THEME = cursorTheme.name;
    };

    services.automatic-sunset.enable = false;

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        exec-once = [
          "systemctl restart --user marble.service swaybg.service"
          "1password"
        ];

        cursor.inactive_timeout = 10;

        misc = {
          # enable_swallow = true;
          # swallow_regex = "^(the-editor)$";
          disable_splash_rendering = true;
          force_default_wallpaper = true;
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

        xwayland = {
          force_zero_scaling = true;
        };

        device = {
          name = "logitech-usb-receiver";
          sensitivity = 0.75;
        };

        gesture = [
          "3, horizontal, workspace"
        ];

        general = {
          layout = "dwindle";

          gaps_in = 8;
          gaps_out = 12;
          border_size = 2;

          "col.active_border" = "rgb(${borderColor})";
          "col.inactive_border" = "rgba(${borderColor}30)";
        };

        dwindle = {
          # TODO could be true?
          preserve_split = true;
          smart_split = true;
        };

        master = {
          orientation = "center";
          slave_count_for_center_master = 0;
        };

        decoration = {
          rounding = 4;

          dim_inactive = true;
          dim_strength = 0;
          dim_special = 0.5;

          shadow = {
            enabled = true;
            offset = "0 5";
            range = 50;
            render_power = 3;
            color = "rgba(1a1a1a1a)";
          };

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
