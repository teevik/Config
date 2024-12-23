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

  # # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  # swapDevices = [{
  #   device = "/var/lib/swapfile";
  #   size = 20 * 1024;
  # }];

  # TODO hibernate
  # boot.resumeDevice = "/dev/disk/by-uuid/f2aecc17-156d-4d2a-ab9f-c6ce222b527b";
  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.extraConfig = "HibernateDelaySec=1h";

  # boot.kernelParams = [
  #   "resume_offset=105984000"
  # ];

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
