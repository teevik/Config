{ pkgs, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
  ];

  teevik = {
    suites = {
      standard.enable = true;
      gaming.enable = true;
    };

    boot = {
      enable = true;
    };

    hardware = {
      light.enable = true;
      bluetooth.enable = true;
    };
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };

    supergfxd = {
      enable = true;
    };
  };

  services.auto-cpufreq.enable = true;

  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.extraConfig = "HibernateDelaySec=1h";

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
