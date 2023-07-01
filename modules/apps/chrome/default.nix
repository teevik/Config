{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.chrome;
in
{
  options.teevik.apps.chrome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable chrome
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.google-chrome = {
        enable = true;
      };
    };
  };
}
