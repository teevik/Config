{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];

  teevik = {
    suites = {
      standard.enable = true;
      gaming.enable = true;
    };

    boot = {
      enable = true;
      efiSysMountPoint = "/boot/efi";
    };

    hardware = {
      nvidia.enable = true;
      bluetooth.enable = true;
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    package = pkgs.teevik.openrgb;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.cpuFreqGovernor = "performance";

  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  time.hardwareClockInLocalTime = true;

  services.udev.packages = with pkgs; [
    vial
    via
  ];

  programs.noisetorch.enable = true;

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
