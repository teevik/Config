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
    ./install-seed.nix
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

    nix = {
      package = perSystem.self.determinate-nix;
      channel.enable = false;
      # Deduplicate on an idle, AC-powered maintenance timer instead of
      # adding hashing/linking work to every build and substitution.
      optimise.automatic = true;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "parallel-eval"
          "wasm-builtin"
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

        keep-derivations = true;
        keep-outputs = true;

        # Leave time for cold proxy requests and temporary Tailscale latency.
        connect-timeout = 15;
        fallback = true;
        narinfo-cache-negative-ttl = 3600;
        require-sigs = true;

        # Prefer ncps for shared results, with a direct public fallback when
        # the proxy is unavailable so cache outages don't rebuild toolchains.
        substituters = lib.mkForce [
          "http://homelab.tail84b6c.ts.net:8501"
          "https://cache.nixos.org"
        ];

        # ncps passes through upstream signatures; clients remain the trust
        # boundary instead of trusting a proxy-generated signing key.
        # CI's .github/ci/nix-conf.sh trusts the same keys.
        trusted-public-keys = [
          (lib.removeSuffix "\n" (builtins.readFile ./homelab-cache.pub))
        ]
        ++ lib.filter (key: key != "") (lib.splitString "\n" (builtins.readFile ./trusted-public-keys.txt));
      };

      # Keep a reproducible registry snapshot, but don't make the system
      # closure depend on unrelated files such as research documents.
      registry.teevik.to = {
        type = "path";
        path = import ./flake-source.nix { inherit lib; };
      };
    };

    # Auto-login
    services.getty.autologinUser = lib.mkForce "teevik";

    # Hardware
    hardware = {
      enableAllFirmware = true;

      graphics = {
        enable = true;
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

    # Override NixOS's Nano default; the standard profile can select Neovim.
    environment.variables.EDITOR = lib.mkOverride 900 "hx";
  };
}
