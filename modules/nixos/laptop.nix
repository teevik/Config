{ pkgs, ... }:
{
  # Suspend when the lid is closed, then hibernate after 1 hour
  # services.logind.lidSwitch = "suspend-then-hibernate";
  # systemd.sleep.extraConfig = "HibernateDelaySec=1h";

  # auto-cpufreq for power management
  # services.auto-cpufreq.enable = true;

  # powerManagement.powertop.enable = true;

  services = {
    # thermald.enable = true;

    upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };

    # auto-cpufreq = {
    #   enable = true;

    #   settings = {
    #     battery = {
    #       governor = "powersave";
    #       # scaling_min_freq = mkDefault (MHz 1800);
    #       # scaling_max_freq = mkDefault (MHz 3900);
    #       # turbo = "never";
    #     };
    #     charger = {
    #       governor = "performance";
    #       # scaling_min_freq = mkDefault (MHz 2000);
    #       # scaling_max_freq = mkDefault (MHz 4800);
    #       # turbo = "auto";
    #     };
    #   };
    # };

    # tlp = {
    #   enable = true;
    #   settings = {
    #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

    #     CPU_MIN_PERF_ON_AC = 0;
    #     CPU_MAX_PERF_ON_AC = 100;
    #     CPU_MIN_PERF_ON_BAT = 0;
    #     CPU_MAX_PERF_ON_BAT = 20;

    #     #Optional helps save long term battery health
    #     START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
    #     STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

    #   };
    # };
  };

  # # https://github.com/NixOS/nixpkgs/issues/211345#issuecomment-1397825573
  # systemd.tmpfiles.rules = map (e: "w /sys/bus/${e}/power/control - - - - auto") [
  #   "pci/devices/0000:00:01.0" # Renoir PCIe Dummy Host Bridge
  #   "pci/devices/0000:00:02.0" # Renoir PCIe Dummy Host Bridge
  #   "pci/devices/0000:00:14.0" # FCH SMBus Controller
  #   "pci/devices/0000:00:14.3" # FCH LPC bridge
  #   "pci/devices/0000:04:00.0" # FCH SATA Controller [AHCI mode]
  #   "pci/devices/0000:04:00.1/ata1" # FCH SATA Controller, port 1
  #   "pci/devices/0000:04:00.1/ata2" # FCH SATA Controller, port 2
  #   "usb/devices/1-3" # USB camera
  # ];

  # Backlight control
  programs.light.enable = true;
  users.users.teevik.extraGroups = [ "video" ];

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
