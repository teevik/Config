{ inputs, pkgs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
  ];

  teevik = {
    hyprland = {
      enableHidpi = true;
    };

    hardware = {
      light.enable = true;
    };

    services = {
      autologin.enable = true;
    };
  };

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
