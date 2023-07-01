{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.shotman;
in
{
  options.teevik.apps.shotman = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable shotman
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      shotman
    ];
  };
}
