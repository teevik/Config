{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      # url = "github:helix-editor/helix";
      url = "github:AlexanderDickie/helix/1de81886505f0deaef257eb4b11df048c09d7573";
      inputs.nixpkgs.follows = "nixpkgs";
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

    roc.url = "github:roc-lang/roc";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake
      {
        inherit inputs;
        src = ./.;

        snowfall = {
          namespace = "teevik";
        };

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
          packages =
            let
              pkgs = channels.nixpkgs;
              cachix-deploy-lib = inputs.cachix-deploy-flake.lib pkgs;
              getDerivation = system: inputs.self.nixosConfigurations.${system}.config.system.build.toplevel;
            in
            {
              cachix-deploy-sync =
                cachix-deploy-lib.spec {
                  agents = {
                    server = getDerivation "server";
                  };
                };

              cachix-deploy-async =
                cachix-deploy-lib.spec {
                  agents = {
                    desktop = getDerivation "desktop";
                    t14s = getDerivation "t14s";
                  };
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
