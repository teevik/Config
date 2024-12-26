{ config, ... }: {
  nixpkgs.config.cudaSupport = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    nvidia.open = false;
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidia.modesetting.enable = true;
  };
}
