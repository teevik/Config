{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.spotify;
in
{
  options.teevik.apps.spotify = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable spotify
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spotify
    ];
  };
}
