{
  perSystem,
  flake,
  inputs,
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

  # Battery
  # hardware.asus.battery.chargeUpto = 80;

  # # Fix keyboard backlight on hibernate
  # powerManagement.resumeCommands = ''
  #   modprobe -r asus_nb_wmi
  #   modprobe asus_nb_wmi
  # '';

  # services.tailscale.enable = lib.mkForce false;
  # networking.wireguard.enable = true;
  # networking.wireguard.interfaces =
  #   let
  #     # [Peer] section -> Endpoint
  #     server_ip = "camp11.campfiresecurity.dk";
  #   in
  #   {
  #     wg0 = {
  #       # [Interface] section -> Address
  #       ips = [ "10.0.240.249/32" ];

  #       # [Peer] section -> Endpoint:port
  #       listenPort = 5000;

  #       # Path to the private key file.
  #       privateKeyFile = "/etc/campfire.key";

  #       peers = [
  #         {
  #           # [Peer] section -> PublicKey
  #           publicKey = "NUCc3FffboVY0PxhfrQB++2DY3rJUyFETabF91Eu3Vc=";
  #           # [Peer] section -> AllowedIPs
  #           allowedIPs = [
  #             "10.42.7.0/24"
  #             "10.0.240.1/32"
  #           ];
  #           # [Peer] section -> Endpoint:port
  #           endpoint = "${server_ip}:5000";
  #           persistentKeepalive = 25;
  #         }
  #       ];
  #     };
  #   };

  boot = {
    # kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-rc;
    # services.scx.enable = true; # by default uses scx_rustland scheduler

    # More power savings
    # https://community.frame.work/t/tracking-linux-battery-life-tuning/6665/594
    # https://discourse.ubuntu.com/t/fine-tuning-the-ubuntu-24-04-kernel-for-low-latency-throughput-and-power-efficiency/44834
    # kernelParams = [
    #   "rcu_nocbs=all"
    #   "rcutree.enable_rcu_lazy=1"
    # ];

    # blacklistedKernelModules = [
    #   "asus-nb-wmi" # Eats ~0.30 W
    # ];

    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=1
    '';
  };

  nixpkgs.overlays = [
    (final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (old: {
        postInstall = ''
          cp ${./firmware/ibt-0190-0291-iml.sfi} $out/lib/firmware/intel/ibt-0190-0291-iml.sfi
          cp ${./firmware/ibt-0190-0291-usb.sfi} $out/lib/firmware/intel/ibt-0190-0291-usb.sfi
        '';
      });

      sof-firmware = perSystem.self.sof-firmware;
    })
  ];

  hardware.firmware = [
    # pkgs.sof-firmware
    # pkgs.alsa-firmware
    # perSystem.self.sof-firmware

    (
      let
        model = "37xx";
        version = "0.0";

        firmware = pkgs.fetchurl {
          url = "https://github.com/intel/linux-npu-driver/raw/v1.13.0/firmware/bin/vpu_${model}_v${version}.bin";
          hash = "sha256-Mpoeq8HrwChjtHALsss/7QsFtDYAoFNsnhllU0xp3os=";
        };
      in
      pkgs.runCommand "intel-vpu-firmware-${model}-${version}" { } ''
        mkdir -p "$out/lib/firmware/intel/vpu"
        cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
      ''
    )
  ];

  system.stateVersion = "24.11";
}
