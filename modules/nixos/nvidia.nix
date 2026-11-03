{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    powerManagement.enable = true;
    modesetting.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # Lets users read the GPU's performance counters, for Nsight Compute (ncu)
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RestrictProfilingToAdminUsers=0
  '';
}
