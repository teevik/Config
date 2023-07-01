{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.opengl;
in
{
  options.teevik.hardware.opengl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable opengl
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };
}
