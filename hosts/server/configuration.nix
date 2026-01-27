{
  flake,
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./services

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  system.autoUpgrade = {
    enable = true;
    flake = "github:teevik/Config";
    allowReboot = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "server";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Disable the lid switch
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Acceleration
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libvdpau-va-gl
      intel-vaapi-driver
      libva-vdpau-driver
    ];
  };

  # SOPS Secrets Configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/teevik/.config/sops/age/keys.txt";

    secrets = {
      # Cloudflare DNS credentials for Let's Encrypt (CF_DNS_API_TOKEN=xxx)
      "cloudflare/api_token" = { };

      # LiteLLM environment (OPENCODE_ZEN_API_KEY=xxx)
      "litellm/env" = { };
    };
  };

  system.stateVersion = "25.11";
}
