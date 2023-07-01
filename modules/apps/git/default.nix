{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.git;
in
{
  options.teevik.apps.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.git = {
        enable = true;
        userEmail = "teemu.vikoren@gmail.com";
        userName = "teevik";
      };
    };
  };
}
