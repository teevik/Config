{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.pulsemixer;
in
{
  options.teevik.apps.pulsemixer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable pulsemixer
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pulsemixer
    ];
  };
}
