{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.exa;
in
{
  options.teevik.apps.exa = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable exa
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.exa = {
        enable = true;

        git = true;

        icons = true;
      };
    };
  };
}
