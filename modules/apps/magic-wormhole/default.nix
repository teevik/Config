{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.magic-wormhole;
in
{
  options.teevik.apps.magic-wormhole = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable magic-wormhole
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      magic-wormhole
    ];
  };
}
