{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nurl;
in
{
  options.teevik.apps.nurl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nurl
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nurl
    ];
  };
}
