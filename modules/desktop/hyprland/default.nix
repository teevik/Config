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

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable {
    environment.loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ]; then
        Hyprland
      fi
    '';

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.hyprland = {
      enable = true;

      xwayland.hidpi = cfg.enableHidpi;
      nvidiaPatches = config.teevik.hardware.nvidia.enable;
    };

    teevik.home = {
      imports = [ inputs.hyprland.homeManagerModules.default ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;

        xwayland.hidpi = cfg.enableHidpi;
        nvidiaPatches = config.teevik.hardware.nvidia.enable;

        # settings = import ./settings.nix {
        #   inherit lib config;
        #   inherit (cfg) enableMasterLayout enableVrr enableHidpi;
        # };

        # # FIXME Manage animations in nix settings if posisble
        # extraConfig = ''
        #   animations {
        #     enabled = true

        #     bezier = myBezier, 0.05, 0.9, 0.1, 1.05

        #     animation = windows, 1, 7, myBezier
        #     animation = windowsOut, 1, 7, default, popin 80%
        #     animation = border, 1, 10, default
        #     animation = borderangle, 1, 8, default
        #     animation = fade, 1, 7, default
        #     animation = workspaces, 1, 6, default
        #   }
        # '';

        extraConfig = import ./config.nix {
          inherit (cfg) enableMasterLayout enableVrr enableHidpi;
          theme = config.teevik.theme;
        };
      };
    };
  };
}
