{ config, lib, ... }:
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
    nixpkgs.config.cudaSupport = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      nvidia.open = true;
      nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidia.modesetting.enable = true;
    };
  };
}
