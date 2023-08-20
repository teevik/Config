{ pkgs, lib, config, inputs, ... }:
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
  };

  imports = [ inputs.hyprland.nixosModules.default ];

  config = mkIf cfg.enable {
    environment.loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ]; then
        Hyprland
      fi
    '';

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      teevik.hyprland-scratchpad
    ];

    programs.hyprland = {
      enable = true;

      nvidiaPatches = config.teevik.hardware.nvidia.enable;
    };
  };
}
