{ self, inputs, config, pkgs, ... }:
let
  initialHashedPassword =
    "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in
{
  imports = [
    ./age
    ./apps
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

  # Nix conifg
  nix = {
    # package = pkgs.lix;
    package = pkgs.callPackage "${self}/packages/lix" { };

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens-github.path}
    '';


    registry = {
      default.flake = inputs.nixpkgs;
      default-flake.flake = inputs.nixpkgs;
      nixpkgs.flake = inputs.nixpkgs;
      teevik.flake = inputs.self;
    };
  };

  nixpkgs.config.allowUnfree = true;
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
  time.timeZone = "Europe/Oslo";

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
  environment.loginShellInit = ''
    if [ "$(tty)" == /dev/tty1 ]; then
      Hyprland
    fi
  '';
}
