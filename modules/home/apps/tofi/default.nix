{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.tofi;
in
{
  options.teevik.apps.tofi = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tofi
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      tofi
    ];

    xdg.configFile."tofi/config".source = ./config;
  };
}
