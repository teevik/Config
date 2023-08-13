{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.xdg;
in
{
  options.teevik.xdg = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable xdg
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;

        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
        };
      };
    };
  };
}
