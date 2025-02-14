{ flake, lib, pkgs, ... }: {
  imports = [
    flake.nixosModules.minimal
    flake.nixosModules.standard
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "minimal";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
  networking.networkmanager.wifi.backend = lib.mkForce "wpa_supplicant";

  system.nixos.variant_id = "installer";

  system.stateVersion = "24.11";
}
