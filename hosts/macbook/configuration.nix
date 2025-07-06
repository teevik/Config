{
  flake,
  inputs,
  lib,
  perSystem,
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
    # "zswap.compressor=zstd"
    "zswap.zpool=zsmalloc"
    "zswap.max_pool_percent=50"
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  # DRM
  environment.sessionVariables.MOZ_GMP_PATH = "${perSystem.self.widevine-firefox}/gmp-widevinecdm/system-installed";

  programs.firefox = {
    policies = {

      Preferences = {
        "media.gmp-widevinecdm.version" = "system-installed";
        "media.gmp-widevinecdm.visible" = true;
        "media.gmp-widevinecdm.enabled" = true;
        "media.gmp-widevinecdm.autoupdate" = false;

        "media.eme.enabled" = true;
        "media.eme.encrypted-media-encryption-scheme.enabled" = true;
      };
    };
  };

  # Touchpad is too damn big
  services.titdb = {
    enable = true;
    device = "/dev/input/event2";
  };

  boot.extraModprobeConfig = ''
    options hid_apple swap_opt_cmd=1 swap_fn_leftctrl=1
  '';

  hardware.asahi = {
    peripheralFirmwareDirectory = ./firmware;
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  system.stateVersion = "25.11";
}
