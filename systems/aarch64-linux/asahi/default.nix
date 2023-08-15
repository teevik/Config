{ inputs, ... }: {
  imports = [
    inputs.nixos-apple-silicon.nixosModules.default
    ./hardware.nix
  ];

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 34 * 1024;
  }];

  options.hardware.asahi = {
    withRust = true;
    addEdgeKernelConfig = true;
    useExperimentalGPUDriver = true;
    experimentalGPUInstallMode = "overlay";
  };

  teevik = {
    boot = {
      enable = true;
      canTouchEfiVariables = false;
    };

    hardware = {
      networking.enable = true;
      pipewire.enable = true;
      firmware.enableAllFirmware = true;
      opengl.enable = true;
    };

    desktop = {
      fonts.enable = true;
      hyprland.enable = true;
    };

    services = {
      autologin.enable = true;
    };

    shells = {
      fish.enable = true;
    };

    suites = {
      # standard.enable = true;
    };
  };
}
