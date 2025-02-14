{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blueprint = {
      url = "github:numtide/blueprint";
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

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [ "x86_64-linux" ];
    };

  #   in
  #   {
  #     nixosConfigurations = lib.mergeAttrsList (map nixosConfigurationFor systems);
  #     homeConfigurations = lib.mergeAttrsList (map homeConfigurationFor systems);

  #     packages.x86_64-linux = let arch = "x86_64-linux"; in {
  #       iso = inputs.nixos-generators.nixosGenerate {
  #         system = arch;
  #         format = "iso";

  #         pkgs = pkgsFor arch;

  #         modules = [
  #           "${self}/nixos/minimal"
  #           ({ config, pkgs, ... }: {
  #             system.stateVersion = "24.11";
  #             networking.hostName = "iso";
  #             nix = nixConfig arch;

  #             system.nixos.variant_id = "installer";
  #             isoImage.isoName = "nixos-minimal-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.system}.iso";
  #           })
  #         ];

  #         specialArgs = { inherit inputs self; };
  #       };
  #     };
  #   };
}
