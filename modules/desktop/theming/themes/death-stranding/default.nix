{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.theming.themes.death-stranding;
in
{
  options.teevik.desktop.theming.themes.death-stranding = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable death-stranding theme
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.theme = { };
  };
}
