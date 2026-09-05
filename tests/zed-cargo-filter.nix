# Compare the real cleaners, including arrays and nested tables, whenever
# Zed or Crane is updated. No package builds or Cargo Git fetches are needed.
{
  flakeRef ? "git+file://${toString ../.}?submodules=1",
  system ? builtins.currentSystem,
}:
let
  flake = builtins.getFlake flakeRef;
  zed = flake.inputs.zed.inputs.zed;
  pkgs = import zed.inputs.nixpkgs { inherit system; };
  original = zed.inputs.crane.mkLib pkgs;
  optimized = (import ../packages/zed/crane.nix zed.inputs.crane).mkLib pkgs;
  manifests = (original.findCargoFiles zed.outPath).cargoTomls;
  sameManifests = builtins.all (
    cargoToml:
    original.cleanCargoToml { inherit cargoToml; } == optimized.cleanCargoToml { inherit cargoToml; }
  ) manifests;
  # Include prefix collisions and deeper descendants, even if today's
  # workspace doesn't contain them. These also exercise the default filter.
  paths = pkgs.lib.cartesianProduct {
    root = [
      "package"
      "workspace"
      "lib"
      "bin"
      "example"
      "test"
      "bench"
      "badges"
      "lints"
      "dependencies"
      "package-extra"
    ];
    field = [
      "authors"
      "metadata"
      "lints"
      "test"
      "required-features"
      "version"
      "dependencies"
      "test-extra"
    ];
  };
  samePredicates =
    builtins.all
      (
        path:
        original.filters.cargoTomlDefault path == optimized.filters.cargoTomlDefault path
        && original.filters.cargoTomlConservative path == optimized.filters.cargoTomlConservative path
      )
      (
        [ [ ] ]
        ++ pkgs.lib.concatMap (pair: [
          [ pair.root ]
          [
            pair.root
            pair.field
          ]
          [
            pair.root
            pair.field
            "nested"
          ]
          [
            pair.root
            pair.field
            "nested"
            "value"
          ]
        ]) paths
      );
in
assert samePredicates;
assert sameManifests;
{
  inherit samePredicates sameManifests;
  manifestCount = builtins.length manifests;
}
