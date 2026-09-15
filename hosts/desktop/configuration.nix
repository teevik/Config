{
  config,
  flake,
  inputs,
  lib,
  perSystem,
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

  # Four evaluator threads slightly beat all 16 SMT threads on the 9800X3D,
  # while using less CPU time. Build concurrency is benchmarked separately.
  nix.settings.eval-cores = 4;

  # Reuse C/C++ compilation across Hyprland rebuilds using the persistent
  # cache exposed by the standard module. Keep upstream's compiler and flags.
  programs.hyprland.package = lib.mkForce (
    perSystem.self.hyprland-cached.override {
      ccacheDir = config.programs.ccache.cacheDir;
    }
  );

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

  # # GitHub Actions Runner
  # users.users.github-runner = {
  #   isSystemUser = true;
  #   group = "users";
  # };

  # sops.secrets.github-runner-token = {
  #   owner = "github-runner";
  # };

  # services.github-runners.desktop = {
  #   enable = true;
  #   user = "github-runner";
  #   name = "desktop";
  #   extraLabels = [ "nixos" ];
  #   url = "https://github.com/teevik/Config";
  #   tokenFile = config.sops.secrets.github-runner-token.path;
  # };

  # nix.settings.trusted-users = [ "github-runner" ];

  # RustDesk Server (signal + relay)
  # services.rustdesk-server = {
  #   enable = true;
  #   openFirewall = true;
  #   signal.relayHosts = [ "desktop" ];
  # };

  programs.noisetorch.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  # Enable bluetooth
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;

  # services = {
  #   asusd = {
  #     enable = true;
  #     enableUserService = true;
  #   };

  #   supergfxd.enable = true;

  #   # fixes mic mute button
  #   udev.extraHwdb = ''
  #     evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
  #      KEYBOARD_KEY_ff31007c=f20
  #   '';
  # };

  # boot = {
  #   kernelParams = [ "pcie_aspm.policy=powersupersave" ];
  # };

  system.stateVersion = "25.11";
}
