{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.flatpak;
in
{
  options.teevik.services.flatpak = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable flatpak
      '';
    };
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
