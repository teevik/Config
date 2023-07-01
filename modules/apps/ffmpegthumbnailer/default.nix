{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.ffmpegthumbnailer;
in
{
  options.teevik.apps.ffmpegthumbnailer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ffmpegthumbnailer
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ffmpegthumbnailer
    ];
  };
}
