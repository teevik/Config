{ inputs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  teevik = {
    suites = {
      standard.enable = true;
      laptop.enable = true;
    };

    boot = {
      enable = true;
    };

    hardware = {
      bluetooth.enable = true;
      light.enable = true;
    };
  };

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
