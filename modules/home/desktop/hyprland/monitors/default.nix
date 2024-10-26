{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.teevik.desktop.hyprland;
  inherit (cfg) scaling;
  cursorSize = builtins.floor (16 * scaling);
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      monitors = {
        default = {
          name = "";
          resolution = "preferred";
          scale = scaling;
        };
      };

      environment.XCURSOR_SIZE = builtins.toJSON (cursorSize * 2);

      config = {
        source = [
          "~/.config/hypr/monitors.conf"
          "~/.config/hypr/workspaces.conf"
        ];
      };
    };
  };
}
