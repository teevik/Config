{ pkgs, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  teevik = {
    boot = {
      enable = true;
    };

    hardware = {
      networking.enable = true;
    };

    shells = {
      fish.enable = true;
    };
  };

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/vda" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
