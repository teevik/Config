{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.bluetooth;
in
{
  options.teevik.hardware.bluetooth = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable bluetooth
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
