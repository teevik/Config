{ pkgs, inputs, ... }:
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

      tailscale = {
        exitNode = "no-osl-wg-001.mullvad.ts.net";
        funnel = 8096;
      };
    };
  };

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

  networking.firewall.allowedTCPPorts = [ 80 8080 ];

  services.sabnzbd = {
    enable = true;

    user = "sabnzbd";
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
