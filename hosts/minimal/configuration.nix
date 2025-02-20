{ flake, lib, pkgs, ... }: {
  imports = [
    flake.nixosModules.minimal
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hosmtName = "minimal";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
  networking.wireless.iwd.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce true;
  networking.networkmanager.wifi.backend = lib.mkForce "iwd";
  users.users.teevik.extraGroups = [ "networkmanager" ];

  system.nixos.variant_id = "installer";

  system.stateVersion = "24.11";

  hardware.firmware = [
    (
      let
        model = "37xx";
        version = "0.0";

        firmware = pkgs.fetchurl {
          url = "https://github.com/intel/linux-npu-driver/raw/v1.13.0/firmware/bin/vpu_${model}_v${version}.bin";
          hash = "sha256-Mpoeq8HrwChjtHALsss/7QsFtDYAoFNsnhllU0xp3os=";
        };
      in
      pkgs.runCommand "intel-vpu-firmware-${model}-${version}" { } ''
        mkdir -p "$out/lib/firmware/intel/vpu"
        cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
      ''
    )
  ];
}
