{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.feh;
in
{
  options.teevik.apps.feh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable feh
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.feh = {
        enable = true;

        buttons = {
          prev_img = null;
          next_img = null;

          zoom_in = 4;
          zoom_out = 5;
        };
      };
    };
  };
}
