{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.nvidia;
in
{
  options.teevik.hardware.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nvidia
      '';
    };
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidia.modesetting.enable = true;

      opengl.extraPackages = with pkgs; [
        vaapiVdpau
      ];
    };
  };
}
