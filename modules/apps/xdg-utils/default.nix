{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.xdg-utils;
in
{
  options.teevik.apps.xdg-utils = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable xdg-utils
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xdg-utils
    ];
  };
}
