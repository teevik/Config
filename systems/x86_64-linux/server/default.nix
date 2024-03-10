{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  teevik = {
    suites = {
      standard.enable = true;
    };

    boot = {
      enable = true;
    };
  };

  services.logind.lidSwitch = "ignore";

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
