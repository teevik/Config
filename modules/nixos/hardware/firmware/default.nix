{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.firmware;
in
{
  options.teevik.hardware.firmware = {
    enableAllFirmware = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable all firmware
      '';
    };
  };

  config = mkIf cfg.enableAllFirmware {
    hardware.enableAllFirmware = true;
  };
}
