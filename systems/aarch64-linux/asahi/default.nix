{ inputs, ... }: {
  imports = [
    ./hardware.nix
    inputs.nixos-apple-silicon.nixosModules.default
  ];

  boot.kernelParams = [
    # Swap fn and ctrl
    "hid_apple.swap_fn_leftctrl=1"

    # Swap opt and cmd
    "hid_apple.swap_opt_cmd=1"
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
    suites = {
      laptop.enable = true;
    };

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
      light.enable = true;
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

    # apps = {
    #   nautilus.enable = true;
    # };
  };
}
