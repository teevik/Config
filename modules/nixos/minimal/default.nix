{
  perSystem,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  initialHashedPassword = "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in
{
  imports = [
    ./networking.nix
    ./ssh.nix
  ];

  config = {
    documentation.man.generateCaches = false;

    # nixpkgs.overlays = [
    #   (final: prev: {
    #     nix = perSystem.nix.default;
    #   })
    # ];

    # TODO shared with home
    nixpkgs.config = {
      allowUnfree = true;
    };

    nix = {
      package = pkgs.nixVersions.nix_2_28;
      channel.enable = false;
      # package = pkgs.lix;
      # package = perSystem.self.lix;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;

        trusted-users = [
          "root"
          "teevik"
        ];

        substituters = [
          "https://cache.nixos.org?priority=10"
          "https://teevik.cachix.org"
          "https://hyprland.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      registry = {
        default.flake = inputs.nixpkgs;
        default-flake.flake = inputs.nixpkgs;
        nixpkgs.flake = lib.mkForce inputs.nixpkgs;
        teevik.flake = inputs.self;
        unstable.flake = inputs.unstable;
      };
    };

    # Auto-login
    services.getty.autologinUser = "teevik";

    # Boot
    boot = {
      supportedFilesystems = [ "bcachefs" ];
      kernelPackages = pkgs.linuxPackages_latest;
    };

    # Hardware
    hardware = {
      enableAllFirmware = true;

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

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

    # Packages
    environment.systemPackages = with pkgs; [
      inputs.home-manager.packages.${pkgs.system}.home-manager
      fh
      magic-wormhole
      git
      helix
    ];

    environment.variables.EDITOR = "hx";
  };
}
