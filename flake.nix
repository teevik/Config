{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # https://github.com/NixOS/nixpkgs/pull/246441
    # nixpkgs.url = "github:RaitoBezarius/nixpkgs/this_has_to_end";
    nur.url = "github:nix-community/NUR";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    devenv = {
      url = "github:cachix/devenv/latest";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-super.url = "github:privatevoid-net/nix-super";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    base16.url = "github:SenchoPens/base16.nix/v2.2.0";

    base16-fish = {
      url = "github:tomyun/base16-fish";
      flake = false;
    };

    base16-zathura = {
      url = "github:haozeke/base16-zathura";
      flake = false;
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun.url = "github:kirottu/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-index-database.follows = "nix-index-database";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      # url = "github:teevik/helix/inline-diagnostics";
      url = "github:helix-editor/helix";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";

    neovim = {
      url = "github:teevik/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caligula = {
      url = "github:ifd3f/caligula";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cachix-deploy-flake = {
      url = "github:cachix/cachix-deploy-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake
      {
        inherit inputs;
        src = ./.;

        package-namespace = "teevik";

        channels-config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowBroken = true;

          permittedInsecurePackages = [
            "electron-24.8.6"
          ];
        };

        systems.modules.nixos = [
          ./nix.nix
        ];

        systems.modules.darwin = [
          ./nix.nix
        ];

        outputs-builder = channels: {
          packages.cachix-deploy =
            let
              pkgs = channels.nixpkgs;
              cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
            in
            cachix-deploy-lib.spec {
              agents =
                let
                  getDerivation = system: inputs.self.nixosConfigurations.${system}.config.system.build.toplevel;
                in
                {
                  desktop = getDerivation "desktop";
                  t14s = getDerivation "t14s";
                  server = getDerivation "server";
                };
            };
        };
      } // {
      templates = {
        devshell = {
          path = ./template/devshell;
          description = "Devshell using flake-parts";
        };

        bevy = {
          path = ./template/bevy;
          description = "Devshell for bevy";
        };

        opengl = {
          path = ./template/opengl;
          description = "Devshell for opengl";
        };
      };
    };
}
