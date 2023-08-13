{ pkgs, config, lib, inputs, system, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.gaming;
in
{
  options.teevik.suites.gaming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gaming suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      apps = {
        steam.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      lutris
    ];
  };
}
