{ inputs, pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.opengl;
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{
  options.teevik.hardware.opengl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable opengl
      '';
    };

    driSupport32Bit = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable driSupport32Bit
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport32Bit = cfg.driSupport32Bit;

      package = pkgs-unstable.mesa.drivers;
      package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    };
  };
}
