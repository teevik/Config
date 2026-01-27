# Escape hatch for Self Host Blocks integration
# SHB requires a patched nixpkgs, so we manually call nixosSystem
# See: https://shb.skarabox.com/usage.html
# TODO: Remove when SHB doesnt use patched nixpkgs anymore
{
  flake,
  inputs,
  hostName,
  ...
}:
let
  system = "x86_64-linux";

  # Get patched nixpkgs from selfhostblocks
  nixpkgs' = inputs.selfhostblocks.lib.${system}.patchedNixpkgs;

  # Import patched nixpkgs with config
  pkgs = import nixpkgs' {
    inherit system;
    config.allowUnfree = true;
  };

  # Build perSystem to match Blueprint's interface
  perSystem = builtins.mapAttrs (
    name: flakeInput:
    (flakeInput.legacyPackages.${system} or { }) // (flakeInput.packages.${system} or { })
  ) inputs;

  specialArgs = {
    inherit
      inputs
      flake
      hostName
      perSystem
      ;
  };
in
{
  class = "nixos";
  value = nixpkgs'.nixosSystem {
    inherit system specialArgs;
    modules = [
      # Self Host Blocks modules
      inputs.selfhostblocks.nixosModules.ssl
      inputs.selfhostblocks.nixosModules.nginx
      inputs.selfhostblocks.nixosModules.postgresql
      inputs.selfhostblocks.nixosModules.lldap
      inputs.selfhostblocks.nixosModules.authelia
      inputs.selfhostblocks.nixosModules.open-webui
      inputs.selfhostblocks.nixosModules.sops

      # sops-nix for secret management
      inputs.sops-nix.nixosModules.sops

      # Home Manager integration
      inputs.home-manager.nixosModules.default
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = specialArgs;
          users.teevik = import ./users/teevik.nix;
        };
      }

      # Main configuration
      ./configuration.nix
    ];
  };
}
