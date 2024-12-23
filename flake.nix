{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable-unfree.url = "github:numtide/nixpkgs-unfree/nixos-unstable";

    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib.url = "https://flakehub.com/f/snowfallorg/lib/3.tar.gz";
    # TODO: Remove this once the flake is updated
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";
    lanzaboote.url = "https://flakehub.com/f/nix-community/lanzaboote/0.3.tar.gz";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-super.url = "github:privatevoid-net/nix-super";
    nh.url = "github:viperML/nh";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    devenv.url = "github:cachix/devenv";
    darwin.url = "github:lnl7/nix-darwin";
    spicetify = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland = {
    #   url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    hyprland-contrib.url = "github:hyprwm/contrib";
    # url = "github:helix-editor/helix";
    helix.url = "github:AlexanderDickie/helix/076d8dde4b9f7a951c1e9b74c26b79689eca5a74";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    neovim.url = "github:teevik/neovim";
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:Mic92/nix-index-database";
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    roc.url = "github:roc-lang/roc";

    base16.url = "github:SenchoPens/base16.nix/v2.2.0";
    base16-fish = {
      url = "github:tomyun/base16-fish";
      flake = false;
    };
    base16-zathura = {
      url = "github:haozeke/base16-zathura";
      flake = false;
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
            "dotnet-sdk-6.0.428"
            "aspnetcore-runtime-6.0.36"
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
