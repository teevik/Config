{ lib, config, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hyprland;
in
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  options.teevik.hyprland = {
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

  config = mkIf cfg.enable {
    environment.loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ]; then
        Hyprland
      fi
    '';

    programs.hyprland = {
      enable = true;

      xwayland.hidpi = cfg.enableHidpi;
      nvidiaPatches = config.teevik.hardware.nvidia.enable;
    };

    teevik.home = {
      imports = [
        inputs.hyprland.homeManagerModules.default
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;
        recommendedEnvironment = true;

        xwayland.hidpi = cfg.enableHidpi;

        nvidiaPatches = config.teevik.hardware.nvidia.enable;

        extraConfig = import ./config.nix {
          inherit (cfg) enableMasterLayout enableVrr;
        };
      };
    };
  };
}
