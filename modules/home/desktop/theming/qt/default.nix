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
    qt = {
      enable = true;

      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
