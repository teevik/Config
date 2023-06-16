{ inputs, pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  teevik = {
    hardware = {
      nvidia.enable = true;
      bluetooth.enable = true;
    };

    hyprland = {
      enableMasterLayout = false;
      enableVrr = true;
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    package = pkgs.teevik.openrgb;
  };

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  powerManagement.cpuFreqGovernor = "performance";

  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  time.hardwareClockInLocalTime = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
