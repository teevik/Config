{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.boot;
in
{
  options.teevik.boot = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable boot
      '';
    };

    canTouchEfiVariables = mkOption {
      default = true;
      type = types.bool;
    };

    efiSysMountPoint = mkOption {
      default = "/boot";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 50;
        };
        # timeout = 0;

        efi = {
          canTouchEfiVariables = cfg.canTouchEfiVariables;
          efiSysMountPoint = cfg.efiSysMountPoint;
        };
      };
    };
  };
}


