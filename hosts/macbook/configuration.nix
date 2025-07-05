{
  flake,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix
    inputs.nixos-apple-silicon.nixosModules.default

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
    inputs.titdb.nixosModules.default
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "macbook";

  boot.kernelParams = [
    # Use whole display
    "apple_dcp.show_notch=1"
    # Enable zswap
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.zpool=zsmalloc"
    "zswap.max_pool_percent=50"
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  services.titdb = {
    enable = true;
    device = "/dev/input/event2";
  };

  boot.extraModprobeConfig = ''
    options hid_apple swap_opt_cmd=1 swap_fn_leftctrl=1
  '';

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.useExperimentalGPUDriver = true;
  hardware.asahi.setupAsahiSound = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub.enable = lib.mkForce true;
    efi.canTouchEfiVariables = lib.mkForce false;
  };

  system.stateVersion = "25.11";
}
