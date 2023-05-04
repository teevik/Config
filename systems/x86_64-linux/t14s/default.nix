{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  teevik.hardware.light.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # powerManagement.cpuFreqGovernor = "powersave";
  services.auto-cpufreq.enable = true;

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
