{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.theming.qt;
in
{
  options.teevik.desktop.theming.qt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable qt theming
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
