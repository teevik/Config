{
  config,
  inputs,
  pkgs,
  lib,
  perSystem,
  ...
}:
let
  initialHashedPassword = "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in
{
  imports = [
    # inputs.determinate.nixosModules.default
    inputs.chaotic.nixosModules.default

    ./networking.nix
    ./ssh.nix
  ];

  config = {
    documentation = {
      man.generateCaches = false;
      doc.enable = false;
      nixos.enable = false;
    };

    # nixpkgs.overlays = [
    #   (final: prev: {
    #     nix = perSystem.nix.default;
    #   })
    # ];

    # TODO shared with home
    nixpkgs.config = {
      allowUnfree = true;

      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
      ];
    };

    # nixpkgs.flake = {
    #   setFlakeRegistry = false;
    #   setNixPath = false;
    # };

    nix = {
      package = perSystem.determinate-nix.default;
      channel.enable = false;
      # package = pkgs.lix;
      # package = perSystem.self.lix;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"

          "ca-derivations"
          "dynamic-derivations"
          "parallel-eval"
        ];
        auto-optimise-store = true;

        trusted-users = [
          "root"
          "teevik"
        ];

        max-substitution-jobs = 128;
        http-connections = 128;

        eval-cores = 0;
        lazy-trees = true;

        keep-derivations = true;
        keep-outputs = true;

        # Timeout quickly if a substituter is unavailable (default is 300s)
        connect-timeout = 5;

        substituters = [
          "https://cache.nixos.org"
          # "https://teevik.cachix.org"
          # "https://hyprland.cachix.org"
          # "https://zed.cachix.org"
          # "https://helix.cachix.org"
          # "https://install.determinate.systems"
        ]
        ++ lib.optional (config.networking.hostName != "desktop") "http://desktop:5000";

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "desktop-1:VvIgYHAClUfjQjKWeNaCiQTRm9Q3fO0Q3v08KLTp0yo="
          # "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
          # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          # "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
          # "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
          # "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        ];
      };

      registry = {
        # default.flake = nixpkgs;
        # default-flake.flake = nixpkgs;
        # nixpkgs.flake = lib.mkForce inputs.nixpkgs-unfree;
        teevik.flake = inputs.self;
      };
    };

    # Auto-login
    services.getty.autologinUser = lib.mkForce "teevik";

    # Boot
    #    boot = {
    #     supportedFilesystems = [ "bcachefs" ];
    #    kernelPackages = pkgs.linuxPackages_latest;
    # };

    # Hardware
    hardware = {
      enableAllFirmware = true;

      graphics = {
        enable = true;
        # enable32Bit = true;
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

      root = {
        initialHashedPassword = lib.mkDefault initialHashedPassword;
      };
    };

    # Packages
    environment.systemPackages = with pkgs; [
      fh
      magic-wormhole
      git
      helix
      stow
    ];

    environment.variables.EDITOR = "hx";
  };
}
