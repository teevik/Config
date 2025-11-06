{ config, ... }:
{
  # nixpkgs.config.cudaSupport = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
  };
}
