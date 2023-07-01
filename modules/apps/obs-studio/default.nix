{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.obs-studio;
in
{
  options.teevik.apps.obs-studio = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable obs-studio
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      obs-studio
    ];
  };
}
