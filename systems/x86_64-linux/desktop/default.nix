{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];

  teevik = {
    suites = {
      standard.enable = true;
      gaming.enable = true;
    };

    boot = {
      enable = true;
      efiSysMountPoint = "/boot/efi";
    };

    hardware = {
      nvidia.enable = true;
      bluetooth.enable = true;
    };

    services = {
      cachix-agent.enable = true;
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    package = pkgs.teevik.openrgb.withPlugins [
      pkgs.openrgb-plugin-effects
      pkgs.openrgb-plugin-hardwaresync
    ];
  };

  # Allows for virtual cam in obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [
    "v4l2loopback"
  ];

  # For dualbooting with windows
  time.hardwareClockInLocalTime = true;


  # Disable hardware cursor
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  programs.noisetorch.enable = true;
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
