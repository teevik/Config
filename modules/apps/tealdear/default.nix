{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.tealdear;
in
{
  options.teevik.apps.tealdear = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tealdear
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      tealdeer
    ];
  };
}
