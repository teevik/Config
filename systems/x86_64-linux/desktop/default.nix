{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  teevik = {
    hardware.nvidia.enable = true;
    hyprland = {
      enableMasterLayout = false;
      enableVrr = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
