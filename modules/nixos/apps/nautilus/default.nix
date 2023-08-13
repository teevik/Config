{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nautilus;
in
{
  options.teevik.apps.nautilus = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nautilus
      '';
    };
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;

    services.gnome.sushi.enable = true;

    environment.systemPackages = with pkgs; [
      gnome.nautilus
      ffmpegthumbnailer
    ];
  };
}
