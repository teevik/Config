{
  flake,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
   ./hardware.nix

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "server";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Disable the lid switch
  services.logind.lidSwitch = "ignore";

  # Docker registry
  services.dockerRegistry = {
    enable = true;

    enableDelete = true;
    enableGarbageCollect = true;
    listenAddress = "0.0.0.0";
  };

  # Acceleration
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.opengl = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libvdpau-va-gl
      vaapiIntel
      vaapiVdpau
    ];
  };

  system.stateVersion = "24.11";
}
