{ lib, config, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.hyprland;
in
{
  options.teevik.desktop.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hyprland
      '';
    };

    enableMasterLayout = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable master layout
      '';
    };

    enableVrr = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable vrr
      '';
    };

    enableHidpi = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hidpi
      '';
    };
  };

  imports = [ inputs.hyprland.homeManagerModules.default ];

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;

      systemdIntegration = true;

      extraConfig = import ./config.nix {
        inherit (cfg) enableMasterLayout enableVrr enableHidpi;
        theme = config.teevik.theme;
      };
    };
  };
}
