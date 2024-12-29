{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-index-database.url = "github:Mic92/nix-index-database";

    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";

    roc.url = "github:roc-lang/roc";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;

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
            system = system.arch;
            modules = [
              system.nixosConfiguration
              { networking.hostName = hostname; }
            ];

            specialArgs = { inherit inputs self; };
          };

        };

      homeConfigurationFor = hostname:
        let system = import ./systems/${hostname}; in {
          "teevik@${hostname}" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.${system.arch};
            modules = [
              system.homeConfiguration
              {
                home = {
                  username = "teevik";
                  homeDirectory = "/home/teevik";
                };
              }
            ];
            extraSpecialArgs = { inherit inputs self; };
          };
        };

    in
    {
      nixosConfigurations = lib.mergeAttrsList (map nixosConfigurationFor systems);
      homeConfigurations = lib.mergeAttrsList (map homeConfigurationFor systems);
    };
}
