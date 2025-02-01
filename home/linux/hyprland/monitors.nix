{ lib, config, ... }:
let
  cfg = config.teevik.hyprland;

  inherit (cfg) scaling cursorName enableVrr;
  cursorSize = builtins.floor (16 * scaling);
in
{
  wayland.windowManager.hyprland = {
    settings = {
      env = [
        "XCURSOR_SIZE,${builtins.toJSON (cursorSize * 2)}"
      ];

      monitor = [
        "Unknown-1,disable"
        ", highrr, auto, ${builtins.toJSON scaling}"
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
}
