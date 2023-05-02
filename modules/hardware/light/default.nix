{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.light;
in
{
  options.teevik.hardware.light = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to install Light backlight control command
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.light.enable = true;

    teevik.user.extraGroups = [ "video" ];
  };
}
