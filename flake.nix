{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    # # You can access packages and modules from different nixpkgs revs
    # # at the same time. Here's an working example:
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    flake-parts.url = "github:hercules-ci/flake-parts";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      # outputs = self.outputs;
      system = "x86_64-linux";
    in
    rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      # packages =
      #   let pkgs = nixpkgs.legacyPackages.${system};
      #   in import ./pkgs { inherit pkgs; };

      # # Devshell for bootstrapping
      # # Acessible through 'nix develop' or 'nix-shell' (legacy)
      # devShells =
      #   let pkgs = nixpkgs.legacyPackages.${system};
      #   in import ./shell.nix { inherit pkgs; };

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays {
        inherit inputs;
      };
      # Reusable nixos modules you might want to export
      # # These are usually stuff you would upstream into nixpkgs
      # nixosModules = import ./modules/nixos;
      # # Reusable home-manager modules you might want to export
      # # These are usually stuff you would upstream into home-manager
      # homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main nixos configuration file <
            ./nixos/configuration.nix
          ];
        };
      };
    };
}
