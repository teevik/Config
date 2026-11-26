{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    powerManagement.enable = true;
    modesetting.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # Hardware video decoding through nvidia-vaapi-driver (NVDEC), which libva
  # doesn't pick on its own. Firefox's RDD sandbox blocks the driver.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  # Lets users read the GPU's performance counters, for Nsight Compute (ncu)
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RestrictProfilingToAdminUsers=0
  '';
}
