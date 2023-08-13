{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.hyprland;
in
{
  options.teevik.suites.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hyprland suite
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
    };
  };
}
