{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.lutris;
in
{
  options.teevik.apps.lutris = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable lutris
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
    ];
  };
}
