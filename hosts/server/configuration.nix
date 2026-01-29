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
    ./lab

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  # Don't delay Tailscale autoconnect on server - other services (dnsmasq) depend on it
  services.tailscale.delayAutoconnect = false;

  system.autoUpgrade = {
    enable = true;
    flake = "github:teevik/Config";
    allowReboot = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "server";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Server needs Docker running at boot for services
  virtualisation.docker.enableOnBoot = true;

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

  # SOPS Secrets Configuration (server-specific)
  # Shared secrets (tailscale, cachix, etc.) come from modules/nixos/standard/sops
  sops.secrets = {
    # Cloudflare DNS credentials for Let's Encrypt (CF_DNS_API_TOKEN=xxx)
    "cloudflare/api_token".sopsFile = ./secrets.yaml;

    # LiteLLM environment (OPENCODE_ZEN_API_KEY=xxx)
    "litellm/env".sopsFile = ./secrets.yaml;

    # LLDAP secrets
    "lldap/jwt_secret".sopsFile = ./secrets.yaml;
    "lldap/user_password".sopsFile = ./secrets.yaml;

    # Authelia secrets
    "authelia/jwt_secret".sopsFile = ./secrets.yaml;
    "authelia/session_secret".sopsFile = ./secrets.yaml;
    "authelia/storage_encryption_key".sopsFile = ./secrets.yaml;
    "authelia/hmac_secret".sopsFile = ./secrets.yaml;
    "authelia/private_key".sopsFile = ./secrets.yaml;

    # Open-WebUI secrets
    "open-webui/oidc_secret".sopsFile = ./secrets.yaml;

    # Monitoring secrets
    "monitoring/admin_password".sopsFile = ./secrets.yaml;
    "monitoring/secret_key".sopsFile = ./secrets.yaml;
    "monitoring/oidc_secret".sopsFile = ./secrets.yaml;

    # Karakeep secrets
    "karakeep/nextauth_secret".sopsFile = ./secrets.yaml;
    "karakeep/meilisearch_key".sopsFile = ./secrets.yaml;
    "karakeep/oidc_secret".sopsFile = ./secrets.yaml;

    # Firefly III secrets
    "firefly-iii/appKey".sopsFile = ./secrets.yaml;
    "firefly-iii/dbPassword".sopsFile = ./secrets.yaml;
    "firefly-iii/oidc_secret".sopsFile = ./secrets.yaml;
    "firefly-iii/importerAccessToken".sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "25.11";
}
