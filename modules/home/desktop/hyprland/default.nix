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
        Whether to enable scaling
      '';
    };

    scaling = mkOption {
      type = types.number;
      default = 1;
      description = ''
        Amount to scale
      '';
    };

    monitor = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable monitor specification
        '';
      };

      resolution = mkOption {
        type = types.str;
        description = ''
          Resolution
        '';
      };

      refreshRate = mkOption {
        type = types.number;
        description = ''
          Refresh rate
        '';
      };

      bitDepth = mkOption {
        type = types.nullOr types.number;
        default = null;
        description = ''
          Refresh rate
        '';
      };
    };
  };

  imports = [ inputs.hyprland.homeManagerModules.default ];

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;

      systemdIntegration = true;

      extraConfig = import ./config.nix {
        inherit config;
        inherit (cfg) enableMasterLayout enableVrr enableHidpi scaling monitor;
      };
    };
  };
}
