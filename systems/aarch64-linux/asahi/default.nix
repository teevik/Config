{ inputs, ... }: {
  imports = [
    ./hardware.nix
    inputs.nixos-apple-silicon.nixosModules.default
  ];

  hardware.asahi = {
    withRust = true;
    addEdgeKernelConfig = true;
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "replace";
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  teevik = {
    boot = {
      enable = true;
      canTouchEfiVariables = false;
    };

    desktop = {
      fonts.enable = true;
      hyprland.enable = true;
    };

    hardware = {
      networking.enable = true;
      pipewire.enable = true;
      firmware.enableAllFirmware = true;
      opengl = {
        enable = true;
        driSupport32Bit = false;
      };
    };

    services = {
      autologin.enable = true;
      # flatpak.enable = true;
      # podman.enable = true;
    };

    shells = {
      fish.enable = true;
    };

    # apps = {
    #   nautilus.enable = true;
    # };
  };
}
