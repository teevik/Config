{ pkgs, ... }:
let
  kernelPackages = pkgs.linuxPackages_zen;
in {
  imports = [ ./hardware.nix ];

  boot.kernelPackages = kernelPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  hardware.nvidia.package = kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
