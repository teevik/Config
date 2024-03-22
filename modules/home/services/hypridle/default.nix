{ inputs, config, lib, pkgs, osConfig ? { }, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.hypridle;

  hyprland = osConfig.programs.hyprland.finalPackage;
  hyprctl = "${hyprland}/bin/hyprctl";
  light = lib.getExe (pkgs.light);
in
{
  imports = [ inputs.hypridle.homeManagerModules.hypridle ];

  options.teevik.services.hypridle = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hypridle
      '';
    };
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      listeners = [
        {
          timeout = 2 * 60;
          onTimeout = "${light} -U 50";
          onResume = "${light} -A 50";
        }

        {
          timeout = 3 * 60;
          onTimeout = "${hyprctl} dispatch dpms off";
          onResume = "${hyprctl} dispatch dpms on";
        }

        {
          timeout = 4 * 60;
          onTimeout = "${hyprctl} dispatch dpms on && ${hyprctl} dispatch exec 'systemctl suspend-then-hibernate'";
        }
      ];
    };
  };
}
