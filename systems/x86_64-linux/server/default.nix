{ inputs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
    inputs.nixarr.nixosModules.default
  ];

  teevik = {
    suites = {
      standard.enable = true;
    };

    boot = {
      enable = true;
    };

    services = {
      healthchecks = {
        enable = true;
        slug = "server";
      };
    };
  };

  nixarr = {
    enable = true;

    mediaDir = "/data/media";
    stateDir = "/data/media/.state";

    jellyfin.enable = true;
    transmission.enable = true;

    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    readarr.enable = true;
    lidarr.enable = true;
  };

  services.tailscale = {
    useRoutingFeatures = "both";
    extraUpFlags = [ "--exit-node=no-osl-wg-007.mullvad.ts.net" ];
  };

  services.logind.lidSwitch = "ignore";

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
