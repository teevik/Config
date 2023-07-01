{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.webcord;
in
{
  options.teevik.apps.webcord = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable webcord
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      webcord
    ];

    teevik.home = {
      xdg.desktopEntries.webcord = {
        name = "WebCord";
        genericName = "discord";
        exec = "webcord %U";
        startupNotify = true;
        categories = [ "Network" "InstantMessaging" ];
      };
    };
  };
}
