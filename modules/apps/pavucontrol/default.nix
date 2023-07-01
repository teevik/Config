{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.pavucontrol;
in
{
  options.teevik.apps.pavucontrol = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable pavucontrol
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pavucontrol
    ];
  };
}
