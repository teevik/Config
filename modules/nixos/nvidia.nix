{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    powerManagement.enable = true;
    modesetting.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;
}
