{ config, lib, inputs, system, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.archetypes.gaming;
in
{
  options.teevik.archetypes.gaming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gaming archetype
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      apps = {
        lutris.enable = true;
        steam.enable = true;
      };
    };
  };
}
