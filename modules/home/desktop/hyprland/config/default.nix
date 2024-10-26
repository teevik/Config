{ inputs, osConfig, lib, config, pkgs, ... }:
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
      type = types.float;
      default = 1.;
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

  imports = [ inputs.hyprnix.homeManagerModules.hyprland ];

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      teevik.hyprland-scratchpad
      pkgs.catppuccin-cursors.mochaDark
    ];

    home.sessionVariables.XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    home.sessionVariables.HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";

    wayland.windowManager.hyprland = {
      enable = true;

      package = osConfig.programs.hyprland.package;

      # config = import ./config/monitor.nix { inherit (cfg) scaling; };

      # plugins = with inputs.hyprland-plugins.packages.${pkgs.system}; [
      #   # hyprexpo
      # ];

      # extraConfig = import ./config.nix {
      #   inherit lib config pkgs;
      #   inherit (cfg) enableMasterLayout enableVrr enableHidpi scaling monitor;
      # };
    };
  };
}
