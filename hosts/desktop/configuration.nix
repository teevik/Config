{
  flake,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.gaming
    flake.nixosModules.nvidia
    flake.nixosModules.binary-cache
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "desktop";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme1n1" ]; };

  # For dualbooting with windows
  time.hardwareClockInLocalTime = true;

  # Infinite timeout for bootloader
  boot.loader.timeout = null;

  # Prevent sleep/suspend - desktop should always be on
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  programs.noisetorch.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  # Enable bluetooth
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;

  # services = {
  #   asusd = {
  #     enable = true;
  #     enableUserService = true;
  #   };

  #   supergfxd.enable = true;

  #   # fixes mic mute button
  #   udev.extraHwdb = ''
  #     evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
  #      KEYBOARD_KEY_ff31007c=f20
  #   '';
  # };

  # boot = {
  #   kernelParams = [ "pcie_aspm.policy=powersupersave" ];
  # };

  system.stateVersion = "25.11";
}
