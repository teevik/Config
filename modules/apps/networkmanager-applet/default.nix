{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.networkmanager-applet;
in
{
  options.teevik.apps.networkmanager-applet = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable networkmanager-applet
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      networkmanagerapplet
    ];
  };
}
