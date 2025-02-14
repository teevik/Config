{ flake, lib, pkgs, ... }: {
  imports = [
    flake.nixosModules.minimal
  ];

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

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
  networking.networkmanager.wifi.backend = lib.mkForce "wpa_supplicant";

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "minimal";
  system.nixos.variant_id = "installer";

  system.stateVersion = "24.11";
}
