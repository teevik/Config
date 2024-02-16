{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.waybar;
in
{
  options.teevik.desktop.waybar = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable waybar
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
  };
}
