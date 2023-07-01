{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.mplayer;
in
{
  options.teevik.apps.mplayer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mplayer
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mplayer
    ];
  };
}
