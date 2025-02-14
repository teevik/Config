{ flake, inputs, lib, pkgs, ... }: {
  imports = [
    ./hardware.nix
    "${inputs.nixos-hardware}/common/cpu/intel"
    "${inputs.nixos-hardware}/common/cpu/intel/comet-lake"
    "${inputs.nixos-hardware}/common/hidpi.nix"

    inputs.disko.nixosModules.disko

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  # Disable home-manager
  home-manager.users = lib.mkForce { };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zenbook";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;

  hardware.firmware = [
    (
      let
        model = "37xx";
        version = "0.0";

        firmware = pkgs.fetchurl {
          url = "https://github.com/intel/linux-npu-driver/raw/v1.2.0/firmware/bin/vpu_${model}_v${version}.bin";
          hash = "sha256-qGhLLiBnOlmF/BEIGC7DEPjfgdLCaMe7mWEtM9uK1mo=";
        };
      in
      pkgs.runCommand "intel-vpu-firmware-${model}-${version}" { } ''
        mkdir -p "$out/lib/firmware/intel/vpu"
        cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
      ''
    )
  ];

  system.stateVersion = "24.11";
}
