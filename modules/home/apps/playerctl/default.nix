{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.playerctl;
in
{
  options.teevik.apps.playerctl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable playerctl
      '';
    };
  };

  config = mkIf cfg.enable {
    services.playerctld.enable = true;

    home.packages = with pkgs; [
      playerctl
    ];
  };
}
