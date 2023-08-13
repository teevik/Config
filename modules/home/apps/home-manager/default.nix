{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.home-manager;
in
{
  options.teevik.apps.home-manager = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable home manager
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;
  };
}
