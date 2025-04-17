{ lib, config, ... }:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.teevik.hyprland;

  inherit (config.teevik.theme) cursorTheme;
  inherit (cfg) scaling enableVrr;
  cursorSize = builtins.floor (16 * scaling);
in
{
  wayland.windowManager.hyprland = {
    settings = mkMerge [
      {
        env = [
          "XCURSOR_SIZE,${builtins.toJSON cursorSize}"
          "HYPRCURSOR_SIZE,${builtins.toJSON (cursorSize * 2)}"
        ];

        monitor = [
          "Unknown-1,disable"
          ", highrr, auto, ${builtins.toJSON scaling}"
        ];

        misc.vrr = enableVrr;
      }

      (mkIf cfg.enableHidpi {
        xwayland = {
          force_zero_scaling = true;
        };

        # env = [
        #   "GDK_SCALE,${builtins.toJSON (builtins.ceil scaling)}"
        # ];

        exec-once = [
          "xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE ${
            builtins.toJSON (builtins.floor (16 * scaling))
          }c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE ${builtins.toJSON scaling}"
          "hyprctl setcursor ${cursorTheme.name} ${builtins.toJSON cursorSize}"
        ];
      })
    ];
  };
}
