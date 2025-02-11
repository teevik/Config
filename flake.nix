{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix.url = "https://flakehub.com/f/NixOS/nix/2.tar.gz";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-index-database.url = "github:Mic92/nix-index-database";
    roc.url = "github:roc-lang/roc";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    hyprland-contrib.url = "github:hyprwm/contrib";
    helix.url = "github:helix-editor/helix";
    neovim.url = "github:teevik/neovim";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-generators, ... }:
    let
      lib = nixpkgs.lib;
      pkgsFor = arch: import nixpkgs {
        system = arch;
        config.allowUnfree = true;
      };

      nixConfig = arch: {
        package = inputs.nix.packages.${arch}.nix;
        channel.enable = false;
        # package = pkgs.lix;
        # package = pkgs.callPackage "${self}/packages/lix" { };

        settings = {
          experimental-features = [ "nix-command" "flakes" ];
          auto-optimise-store = true;

          trusted-users = [
            "root"
            "teevik"
          ];

          substituters = [
            "https://cache.nixos.org?priority=10"
            "https://teevik.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
          ];
        };

        registry = {
          default.flake = inputs.nixpkgs;
          default-flake.flake = inputs.nixpkgs;
          nixpkgs.flake = inputs.nixpkgs;
          teevik.flake = inputs.self;
        };
      };

      foldersIn = path:
        let
          everything = builtins.readDir path;
          directories =
            lib.filterAttrs (name: type: type == "directory") everything;
        in
        builtins.attrNames directories;

      systems = foldersIn ./systems;

      nixosConfigurationFor = hostname:
        let system = import ./systems/${hostname}; in {
          ${hostname} = lib.nixosSystem {
            pkgs = pkgsFor system.arch;
            system = system.arch;

            modules = [
              system.nixosConfiguration
              {
                networking.hostName = hostname;
                nix = nixConfig system.arch;
              }
            ];

            specialArgs = { inherit inputs self; };
          };
        };

      homeConfigurationFor = hostname:
        let system = import ./systems/${hostname}; in {
          "teevik@${hostname}" = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsFor system.arch;

            modules = [
              system.homeConfiguration
              {
                home = {
                  username = "teevik";
                  homeDirectory = "/home/teevik";
                };
                nix = nixConfig system.arch;
              }
            ];

            extraSpecialArgs = { inherit inputs self; };
          };
        };

    in
    {
      nixosConfigurations = lib.mergeAttrsList (map nixosConfigurationFor systems);
      homeConfigurations = lib.mergeAttrsList (map homeConfigurationFor systems);

      packages.x86_64-linux = let arch = "x86_64-linux"; in {
        iso = inputs.nixos-generators.nixosGenerate {
          system = arch;
          format = "iso";

          pkgs = pkgsFor arch;

          modules = [
            "${self}/nixos/minimal"
            ({ config, pkgs, ... }: {
              system.stateVersion = "24.11";
              networking.hostName = "iso";
              nix = nixConfig arch;

              system.nixos.variant_id = "installer";
              isoImage.isoName = "nixos-minimal-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.system}.iso";
            })
          ];

          specialArgs = { inherit inputs self; };
        };
      };
    };
}
