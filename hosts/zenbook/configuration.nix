{
  config,
  inputs,
  perSystem,
  flake,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware.nix
    "${inputs.nixos-hardware}/common/cpu/intel"
    "${inputs.nixos-hardware}/common/cpu/intel/lunar-lake"
    "${inputs.nixos-hardware}/common/hidpi.nix"
    # "${inputs.nixos-hardware}/asus/battery.nix"

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
    flake.nixosModules.gaming
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zenbook";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Logitech
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  networking.firewall.allowedTCPPorts = [ 9001 ];

  # Virt manager
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "teevik" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # Twitch Drops Miner
  virtualisation.oci-containers = {
    backend = "docker";
    containers.twitchdropsminer = {
      image = "docker.io/nokodo/twitchdropsminer:latest";
      autoStart = true;
      pull = "always";
      ports = [ "127.0.0.1:5800:5800" ];
      environment = {
        DARK_MODE = "1";
        USER_ID = "568";
        GROUP_ID = "568";
      };
      user = "568:568";
      volumes = [
        "/var/lib/twitchdropsminer/config:/config"
        "/var/lib/twitchdropsminer/cache:/cache"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/twitchdropsminer 0750 568 568 -"
    "d /var/lib/twitchdropsminer/config 0750 568 568 -"
    "d /var/lib/twitchdropsminer/cache 0750 568 568 -"
  ];

  networking.firewall.checkReversePath = false;
  services.resolved.enable = true;

  # services.mullvad-vpn.enable = true;
  # services.mullvad-vpn.package = pkgs.mullvad-vpn;

  environment.systemPackages = with pkgs; [
    virtiofsd
    sof-firmware
    wireguard-tools
    protonvpn-gui
  ];

  # TODO: remove when https://nixpk.gs/pr-tracker.html?pr=449133 is merged
  hardware.graphics.extraPackages = lib.mkForce (
    with pkgs;
    [
      intel-media-driver
      vpl-gpu-rt
    ]
  );

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  system.stateVersion = "24.11";
}
