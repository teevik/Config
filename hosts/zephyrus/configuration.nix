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
    "${inputs.nixos-hardware}/common/hidpi.nix"
    "${inputs.nixos-hardware}/common/cpu/amd"
    "${inputs.nixos-hardware}/common/cpu/amd/pstate.nix"
    "${inputs.nixos-hardware}/common/gpu/amd"
    "${inputs.nixos-hardware}/common/pc/laptop"
    "${inputs.nixos-hardware}/common/pc/ssd"


    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zephyrus";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services = {
    asusd.enable = true;

    # fixes mic mute button
    udev.extraHwdb = ''
      evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
       KEYBOARD_KEY_ff31007c=f20
    '';
  };

  boot = {
    kernelParams = [ "pcie_aspm.policy=powersupersave" ];
  };

  system.stateVersion = "25.11";
}
