{ config, lib, ... }:
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

    efiSysMountPoint = mkOption {
      default = "/boot";
      type = types.str;
      description = "Where the EFI System Partition is mounted.";
    };
  };

  config = mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = true;
      timeout = 0;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = cfg.efiSysMountPoint;
      };
    };
  };
}


