{ inputs
, pkgs
, ...
}: {
  imports = [
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 34 * 1024;
  }];

  boot.resumeDevice = "/dev/disk/by-uuid/7c5b49de-9b7b-44d9-a8fa-e0ed6d2a23bd";
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" "resume_offset=104239104" ];

  systemd.services = {
    ath11k-suspend = {
      enable = true;

      description = "Suspend: rmmod ath11k_pci";
      before = [ "sleep.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "/run/current-system/sw/bin/rmmod ath11k_pci";
      };

      wantedBy = [ "sleep.target" ];
    };

    ath11k-resume = {
      enable = true;

      description = "Resume: modprobe ath11k_pci";
      after = [ "post-resume.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "/run/current-system/sw/bin/modprobe ath11k_pci";
      };

      wantedBy = [ "post-resume.target" ];
    };
  };

  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.extraConfig = "HibernateDelaySec=2h";

  teevik = {
    archetypes = {
      workstation.enable = true;
      gaming.enable = true;
    };

    hardware = {
      bluetooth.enable = true;
    };

    hardware = {
      light.enable = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };


  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # powerManagement.cpuFreqGovernor = "powersave";
  services.auto-cpufreq.enable = true;

  services.fwupd.enable = true;

  # boot.kernelParams = [ "amd_pstate=passive" ];

  # boot.kernelModules = [ "amd-pstate" ];
  # boot.initrd.kernelModules = [ "amdgpu" ];

  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";

  #     # # The following prevents the battery from charging fully to
  #     # # preserve lifetime. Run `tlp fullcharge` to temporarily force
  #     # # full charge.
  #     # # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
  #     # START_CHARGE_THRESH_BAT0 = 40;
  #     # STOP_CHARGE_THRESH_BAT0 = 50;

  #     # 100 being the maximum, limit the speed of my CPU to reduce
  #     # heat and increase battery usage:
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MAX_PERF_ON_BAT = 20;
  #   };
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
