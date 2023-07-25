{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.theming.themes.catppuccin;
in
{
  options.teevik.desktop.theming.themes.catppuccin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable catppuccin theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.theme = { };
  };
}
