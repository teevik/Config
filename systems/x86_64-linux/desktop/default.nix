{ inputs, pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  teevik = {
    hardware.nvidia.enable = true;
    hyprland = {
      enableMasterLayout = false;
      enableVrr = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Lanzaboote
  boot.bootspec.enable = true;
  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  time.hardwareClockInLocalTime = true;

  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
