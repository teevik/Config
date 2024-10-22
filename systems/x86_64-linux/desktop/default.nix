{ lib, config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    # inputs.lanzaboote.nixosModules.lanzaboote
  ];

  teevik = {
    suites = {
      standard.enable = true;
      gaming.enable = true;
    };

    boot.enable = true;

    hardware = {
      nvidia.enable = true;
      bluetooth.enable = true;
    };

    services = {
      cachix-agent.enable = true;
    };
  };

  # boot.loader.systemd-boot.enable = lib.mkForce false;

  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/etc/secureboot";
  # };

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
    probe-rs
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666"
  '';

  powerManagement.cpuFreqGovernor = "performance";

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
