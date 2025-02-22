{ flake, inputs, lib, pkgs, ... }: {
  imports = [
    ./hardware.nix
    "${inputs.nixos-hardware}/common/cpu/intel"
    "${inputs.nixos-hardware}/common/cpu/intel/comet-lake"
    "${inputs.nixos-hardware}/common/hidpi.nix"

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
    flake.nixosModules.gaming
  ];

  # Disable home-manager
  home-manager.users = lib.mkForce { };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zenbook";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Fix keyboard backlight on hibernate
  powerManagement.resumeCommands = ''
    modprobe -r asus_nb_wmi
    modprobe asus_nb_wmi
  '';

  #     services.tailscale.enable = lib.mkForce false;
  # networking.wireguard.enable = true;
  # networking.wireguard.interfaces = let
  #   # [Peer] section -> Endpoint
  #   server_ip = "camp13.campfiresecurity.dk";
  # in {
  #   wg0 = {
  #     # [Interface] section -> Address
  #     ips = [ "10.0.240.254/32" ];

  #     # [Peer] section -> Endpoint:port
  #     listenPort = 5000;

  #     # Path to the private key file.
  #     privateKeyFile = "/etc/campfire.key";

  #     peers = [{
  #       # [Peer] section -> PublicKey
  #       publicKey = "BWwE1s30zX4WLoI9/DJgzRFpMhU5Un/heT5fvm7fzQQ=";
  #       # [Peer] section -> AllowedIPs
  #       allowedIPs = [ "10.42.9.0/24" "10.0.240.1/32" ];
  #       # [Peer] section -> Endpoint:port
  #       endpoint = "${server_ip}:5000";
  #       persistentKeepalive = 25;
  #     }];
  #   };
  # };

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
    # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-rc;
    # services.scx.enable = true; # by default uses scx_rustland scheduler

    # More power savings
    # https://community.frame.work/t/tracking-linux-battery-life-tuning/6665/594
    # https://discourse.ubuntu.com/t/fine-tuning-the-ubuntu-24-04-kernel-for-low-latency-throughput-and-power-efficiency/44834
    kernelParams = [
      "rcu_nocbs=all"
      "rcutree.enable_rcu_lazy=1"
    ];

    # blacklistedKernelModules = [
    #   "asus-nb-wmi" # Eats ~0.30 W
    # ];
  };


  hardware.firmware = [
    pkgs.sof-firmware
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
