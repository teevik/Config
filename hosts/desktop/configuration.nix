{
  flake,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.gaming
    flake.nixosModules.nvidia
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "desktop";

  # For dualbooting with windows
  time.hardwareClockInLocalTime = true;

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
