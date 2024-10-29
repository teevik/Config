{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.teevik.desktop.hyprland;

  inherit (cfg) scaling cursorName enableVrr;
  cursorSize = builtins.floor (16 * scaling);
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        env = [
          "XCURSOR_SIZE,${builtins.toJSON (cursorSize * 2)}"
        ];

        monitor = [
          "Unknown-1,disable"
          ", highrr, auto, 1"
        ];

        misc.vrr = enableVrr;
      } // (lib.attrsets.optionalAttrs cfg.enableHidpi {
        xwayland = {
          force_zero_scaling = true;
        };

        env = [
          "GDK_SCALE,${builtins.toJSON scaling}"
        ];

        exec-once = [
          "xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE ${builtins.toJSON (builtins.floor (16 * scaling))}c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE ${builtins.toJSON scaling}"
          "hyprctl setcursor ${cursorName} ${builtins.toJSON cursorSize}"
        ];
      });
    };
  };
}
