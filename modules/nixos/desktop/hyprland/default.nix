{ lib, config, pkgs, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.hyprland;
  hyprlandPackages = inputs.hyprland.packages.${pkgs.system};
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
  };

  config = mkIf cfg.enable {
    environment.loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ]; then
        Hyprland
      fi
    '';

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with hyprlandPackages; [
      nwg-displays
    ];

    programs.hyprland = {
      enable = true;

      package = hyprlandPackages.hyprland;
      portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
    };
  };
}
