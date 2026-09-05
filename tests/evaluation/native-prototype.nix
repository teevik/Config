# EXPERIMENT: only the outputs needed to evaluate this repo's NixOS hosts.
# This deliberately does not implement Blueprint's checks, system-manager,
# templates, or public package platform filtering. It is a benchmark, not
# a replacement flake framework.
{
  inputs,
  nixpkgs,
  systems,
  ...
}:
let
  lib = inputs.nixpkgs.lib;
  flake = inputs.self;
  src = flake.outPath;
  perSystem =
    system:
    builtins.mapAttrs (
      name: input:
      (input.legacyPackages.${system} or { })
      // (if name == "self" then packages.${system} else input.packages.${system} or { })
    ) inputs;
  pkgsFor = lib.genAttrs systems (
    system:
    import inputs.nixpkgs {
      inherit system;
      config = nixpkgs.config or { };
      overlays = nixpkgs.overlays or [ ];
    }
  );
  pathsIn =
    dir:
    lib.mapAttrs'
      (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = dir + "/${name}";
      })
      (
        lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name) (
          builtins.readDir dir
        )
      );
  packages = lib.genAttrs systems (
    system:
    let
      scope = lib.makeScope lib.callPackageWith (_: {
        inherit inputs flake system;
        pkgs = pkgsFor.${system};
        perSystem = perSystem system;
      });
    in
    builtins.mapAttrs (pname: path: scope.newScope { inherit pname; } path { }) (
      pathsIn (src + "/packages")
    )
  );
  hostNames = builtins.attrNames (
    lib.filterAttrs (name: _: builtins.pathExists (src + "/hosts/${name}/configuration.nix")) (
      builtins.readDir (src + "/hosts")
    )
  );
in
{
  inherit packages;
  nixosModules = pathsIn (src + "/modules/nixos");
  modules = lib.genAttrs [ "nixos" "shared" ] (name: pathsIn (src + "/modules/${name}"));
  nixosConfigurations = lib.genAttrs hostNames (
    hostName:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs flake hostName; };
      modules = [
        (
          { config, lib, ... }:
          {
            nixpkgs.pkgs = lib.mkDefault pkgsFor.${config.nixpkgs.hostPlatform.system};
            _module.args.perSystem = perSystem config.nixpkgs.hostPlatform.system;
          }
        )
        (src + "/hosts/${hostName}/configuration.nix")
      ];
    }
  );
}
