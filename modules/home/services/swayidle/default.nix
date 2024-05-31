{ config, lib, pkgs, osConfig ? { }, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.swayidle;

  hyprland = osConfig.programs.hyprland.package;
  hyprctl = "${hyprland}/bin/hyprctl";
  light = lib.getExe (pkgs.light);
in
{
  options.teevik.services.swayidle = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable swayidle
      '';
    };
  };

  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;

      systemdTarget = "hyprland-session.target";

      timeouts = [
        {
          timeout = 2 * 60;
          command = "${light} -U 50";
          resumeCommand = "${light} -A 50";
        }

        {
          timeout = 3 * 60;
          command = "${hyprctl} dispatch dpms off";
          resumeCommand = "${hyprctl} dispatch dpms on";
        }

        {
          timeout = 4 * 60;
          command = "${hyprctl} dispatch dpms on && ${hyprctl} dispatch exec 'systemctl suspend-then-hibernate'";
        }
      ];
    };
  };
}
