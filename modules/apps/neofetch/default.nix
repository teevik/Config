{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.neofetch;
  neofetchImage = config.teevik.theme.neofetchImage;
in
{
  options.teevik.apps.neofetch = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable neofetch
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (teevik.neofetch.override (lib.optionalAttrs (neofetchImage != null) {
        inherit neofetchImage;
      }))
    ];
  };
}
