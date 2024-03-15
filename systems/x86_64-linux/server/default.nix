{ pkgs, inputs, ... }:
let
  html = pkgs.stdenv.mkDerivation {
    name = "html";
    src = ./html;

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out
      cp -R $src/* $out
    '';
  };
in
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

    jellyfin.enable = true;
    transmission.enable = true;

    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    # readarr.enable = true;
    # lidarr.enable = true;
  };

  system.activationScripts = {
    "nixarr" = /* bash */''
      mkdir -p /data/.state/nixarr/transmission/.config/transmission-daemon
      chown torrenter:torrenter /data/.state/nixarr/transmission/.config/transmission-daemon
    '';
  };

  services.static-web-server = {
    enable = true;
    root = "${html}";
    listen = "[::]:80";
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

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
