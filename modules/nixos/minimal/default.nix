{
  config,
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
    ./networking.nix
    ./parallel-eval.nix
    ./ssh.nix
  ];

  config = {
    # Blueprint already creates the configured package set for this platform.
    # Avoid NixOS re-instantiating it through appendOverlays, even for [].
    # Hosts that need overlays (e.g. Apple Silicon) retain the normal behavior.
    _module.args.pkgs = lib.mkForce (
      if config.nixpkgs.overlays == [ ] then
        config.nixpkgs.pkgs
      else
        config.nixpkgs.pkgs.appendOverlays config.nixpkgs.overlays
    );

    documentation = {
      man.cache.enable = false;
      # Fish enables this separately, even when the cache is disabled above.
      # Avoid rebuilding and indexing all system man pages on each switch.
      man.cache.generateAtRuntime = false;
      doc.enable = false;
      nixos.enable = false;
    };

    # nixpkgs.overlays = [
    #   (final: prev: {
    #     nix = perSystem.nix.default;
    #   })
    # ];

    # nixpkgs.flake = {
    #   setFlakeRegistry = false;
    #   setNixPath = false;
    # };

    nix = {
      package = perSystem.determinate-nix.default;
      channel.enable = false;
      # Deduplicate on an idle, AC-powered maintenance timer instead of
      # adding hashing/linking work to every build and substitution.
      optimise.automatic = true;
      # package = pkgs.lix;
      # package = perSystem.self.lix;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "parallel-eval"
        ];

        auto-optimise-store = false;

        trusted-users = [
          "root"
          "teevik"
        ];

        max-substitution-jobs = 32;
        http-connections = 32;

        eval-cores = lib.mkDefault 0;
        lazy-trees = true;

        # Built against the same Determinate Nix components as `nix.package`,
        # since the plugin ABI is not stable across Nix versions.
        plugin-files = "${perSystem.self.cargo-nix-plugin}/lib/nix/plugins";

        keep-derivations = true;
        keep-outputs = true;

        # The cache is normally about 2 ms away over Tailscale.
        connect-timeout = 2;
        fallback = true;
        narinfo-cache-negative-ttl = 3600;
        require-sigs = true;

        # ncps fans out to the upstream caches once and shares warm results
        # across every machine on the tailnet.
        substituters = lib.mkForce [ "http://homelab.tail84b6c.ts.net:8501" ];

        # ncps passes through upstream signatures; clients remain the trust
        # boundary instead of trusting a proxy-generated signing key.
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "desktop-1:VvIgYHAClUfjQjKWeNaCiQTRm9Q3fO0Q3v08KLTp0yo="
          "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
          "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
          "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
          "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
          "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
          "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
          "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
          "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      # Keep a reproducible registry snapshot, but don't make the system
      # closure depend on unrelated stowed dotfiles or research documents.
      registry.teevik.to = {
        type = "path";
        path = import ./flake-source.nix { inherit lib; };
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

    environment.variables.EDITOR = "nvim";
  };
}
