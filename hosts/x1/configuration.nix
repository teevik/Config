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
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  # Disable home-manager
  home-manager.users = lib.mkForce { };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "x1";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  system.stateVersion = "24.11";
}
