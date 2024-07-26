{ lib, config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
    inputs.nixarr.nixosModules.default
  ];

  nix.package = lib.mkForce pkgs.nix;

  teevik = {
    suites = {
      standard.enable = true;
    };

    boot = {
      enable = true;
    };

    hardware = {
      light.enable = true;
    };

    services = {
      healthchecks = {
        enable = true;
        slug = "server";
      };

      tailscale = {
        exitNode = "no-osl-wg-001.mullvad.ts.net";
        funnel = 8096;
      };

      tailscale-proxy = {
        enable = true;

        proxies = {
          jellyfin = {
            hostname = "jellyfin";
            port = 8096;
          };

          radarr = {
            hostname = "radarr";
            port = 7878;
          };

          sonarr = {
            hostname = "sonarr";
            port = 8989;
          };

          prowlarr = {
            hostname = "prowlarr";
            port = 9696;
          };

          stirling = {
            hostname = "stirling";
            port = 8081;
          };
        };
      };

      stirling-pdf = {
        enable = true;
        port = 8081;
      };
    };

    services = {
      cachix-agent.enable = true;
    };
  };

  users.users.github-runner = {
    isSystemUser = true;
    group = "users";
  };

  age = {
    secrets.runner-token = {
      file = ./secrets/runner-token.age;
      owner = "github-runner";
    };
  };

  services.github-runners.server = {
    enable = true;
    user = "github-runner";
    name = "server";
    extraLabels = [ "nixos" ];
    url = "https://github.com/teevik/Config";
    tokenFile = config.age.secrets.runner-token.path;

    extraPackages = with pkgs; [
      cachix
    ];
  };

  nix.settings.trusted-users = [ "github-runner" ];

  # https://wiki.archlinux.org/title/intel_graphics
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.opengl = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libvdpau-va-gl
      vaapiIntel
      vaapiVdpau
    ];
  };

  nixarr = {
    enable = true;

    jellyfin.enable = true;
    transmission.enable = true;

    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
  };

  system.activationScripts = {
    "nixarr" = /* bash */''
      mkdir -p /data/.state/nixarr/transmission/.config/transmission-daemon
      chown torrenter:torrenter /data/.state/nixarr/transmission/.config/transmission-daemon
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 8081 ];

  services.sabnzbd = {
    enable = true;

    user = "usenet";
    group = "media";
  };

  services.static-web-server =
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
      enable = true;
      root = "${html}";
      listen = "[::]:80";
    };

  services.logind.lidSwitch = "ignore";

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
