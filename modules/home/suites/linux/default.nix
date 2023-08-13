{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.linux;
in
{
  options.teevik.suites.linux = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable linux suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      desktop = {
        hyprland = {
          enable = true;

          enableMasterLayout = false;
          enableVrr = false;
        };

        mako.enable = true;
        swaybg.enable = true;
        waybar.enable = true;

        theming = {
          gtk.enable = true;
          qt.enable = true;
        };
      };

      apps = {
        playerctl.enable = true;
      };

      xdg.enable = true;
    };

    home.packages = with pkgs; [
      shotman
    ];
  };
}
