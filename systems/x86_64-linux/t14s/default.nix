{ inputs
, pkgs
, ...
}: {
  imports = [
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  # HW acceleration
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
  ];
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 34 * 1024;
  }];

  # Hibernate
  boot.resumeDevice = "/dev/disk/by-uuid/7c5b49de-9b7b-44d9-a8fa-e0ed6d2a23bd";
  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "resume_offset=104239104"

    # https://gitlab.freedesktop.org/drm/amd/-/issues/2539
    "acpi_mask_gpe=0x0e"
    "gpiolib_acpi.ignore_interrupt=AMDI0030:00@18"
  ];

  systemd.services = {
    ath11k-fix = {
      enable = true;

      description = "Suspend fix for ath11k_pci";
      before = [ "sleep.target" ];

      unitConfig = {
        StopWhenUnneeded = "yes";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "/run/current-system/sw/bin/modprobe -r ath11k_pci";
        ExecStop = "/run/current-system/sw/bin/modprobe ath11k_pci";
      };

      wantedBy = [ "sleep.target" ];
    };
  };

  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.extraConfig = "HibernateDelaySec=1h";

  teevik = {
    suites = {
      standard.enable = true;
      laptop.enable = true;

      gaming.enable = true;
    };

    boot = {
      enable = true;
      efiSysMountPoint = "/boot/efi";
    };

    hardware = {
      bluetooth.enable = true;
    };

    hardware = {
      light.enable = true;
    };

    services = {
      cachix-agent.enable = true;
    };
  };

  # Disable hardware cursor
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # powerManagement.cpuFreqGovernor = "powersave";
  # boot.kernelParams = [ "amd_pstate=passive" ];

  # boot.kernelModules = [ "amd-pstate" ];
  # boot.initrd.kernelModules = [ "amdgpu" ];

  # Virt manager
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    probe-rs
    virtiofsd
  ];

  # Pico probe
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666"
  '';

  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "teevik" ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
