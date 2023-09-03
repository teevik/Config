{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # https://github.com/NixOS/nixpkgs/pull/246441
    # nixpkgs.url = "github:RaitoBezarius/nixpkgs/this_has_to_end"; 

    nur.url = "github:nix-community/NUR";

    snowfall-lib = {
      url = "github:snowfallorg/lib/feat/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      # inputs.nixpkgs.follows = "nixpkgs";
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

    base16.url = "github:SenchoPens/base16.nix";

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

    neovim-flake = {
      url = "github:NotAShelf/neovim-flake";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun.url = "github:kirottu/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";
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
        };

        systems.modules.nixos = [
          ./nix.nix
        ];

        systems.modules.darwin = [
          ./nix.nix
        ];
      } // {
      templates.devshell = {
        path = ./template/devshell;
        description = "Devshell using flake-parts";
      };
    };
}
