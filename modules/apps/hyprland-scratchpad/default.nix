{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.hyprland-scratchpad;
in
{
  options.teevik.apps.hyprland-scratchpad = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable hyprland-scratchpad
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      teevik.hyprland-scratchpad
    ];
  };
}
