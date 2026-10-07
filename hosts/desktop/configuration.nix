{
  flake,
  inputs,
  ...
}:
{
  imports = [
    ./hardware.nix

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.gaming
    flake.nixosModules.nvidia
    flake.nixosModules.binary-cache
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "desktop";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme1n1" ]; };

  services.hypridle.settings = {
    general = {
      before_sleep_cmd = "hyprctl dispatch dpms off";
      after_sleep_cmd = "hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 600;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on";
      }
    ];
  };

  # For dualbooting with windows
  time.hardwareClockInLocalTime = true;

  # Infinite timeout for bootloader
  boot.loader.timeout = null;

  programs.noisetorch.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  system.stateVersion = "25.11";
}
