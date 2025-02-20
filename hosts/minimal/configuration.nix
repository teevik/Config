{ flake, lib, pkgs, ... }: {
  imports = [
    flake.nixosModules.minimal
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "minimal";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
  networking.wireless.iwd.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce true;
  networking.networkmanager.wifi.backend = lib.mkForce "iwd";

  system.nixos.variant_id = "installer";

  system.stateVersion = "24.11";
}
