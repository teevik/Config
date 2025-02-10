{ config, pkgs, ... }:
let
  initialHashedPassword =
    "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in
{
  imports = [
    ./age
    ./apps
    ./cachix.nix
    ./docker.nix
    ./fonts.nix
    ./hyprland.nix
    ./network.nix
    ./pipewire.nix
    ./polkit.nix
    ./shells.nix
    ./ssh.nix
    ./tailscale.nix
  ];

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens-github.path}
    '';
  };

  documentation.man.generateCaches = false;

  # Boot
  boot = {
    supportedFilesystems = [ "bcachefs" ];
    kernelPackages = pkgs.linuxPackages_latest;

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "150%";

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 50;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # TimeZone
  services.automatic-timezoned.enable = true;

  services.geoclue2 = {
    enable = true;
    geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    submissionUrl = "https://api.beacondb.net/v2/geosubmit";

    enableNmea = false;
  };
  # time.timeZone = "Europe/Oslo";

  # User
  users.users = {
    teevik = {
      isNormalUser = true;
      home = "/home/teevik";
      group = "users";

      extraGroups = [ "wheel" ];


      inherit initialHashedPassword;
    };

    root = { inherit initialHashedPassword; };
  };

  # Hardware
  hardware = {
    enableAllFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Auto login
  services.getty.autologinUser = "teevik";
  # TODO enable this
  # environment.loginShellInit = ''
  #   if [ "$(tty)" == /dev/tty1 ]; then
  #     Hyprland
  #   fi
  # '';
}
