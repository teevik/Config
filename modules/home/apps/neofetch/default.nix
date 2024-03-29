{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.neofetch;
  themeNeofetchImage = config.teevik.theme.neofetchImage;
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

    neofetchImage = mkOption {
      type = types.nullOr types.path;
      default = themeNeofetchImage;
      description = ''
        Specific neofetch image
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (teevik.neofetch.override (lib.optionalAttrs (cfg.neofetchImage != null) {
        inherit (cfg) neofetchImage;
      }))
    ];
  };
}
