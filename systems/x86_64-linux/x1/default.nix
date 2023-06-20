{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  teevik = {
    hardware = {
      light.enable = true;
    };

    services = {
      autologin.enable = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
