{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.theming.qt;
in
{
  options.teevik.theming.qt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable qt theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      qt = {
        enable = true;

        platformTheme = "gnome";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };
    };
  };
}
