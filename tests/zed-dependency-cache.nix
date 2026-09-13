# nix eval --impure --json --expr 'import ./tests/zed-dependency-cache.nix {}'
# Application revision changes must not invalidate third-party compilation.
{
  flakeRef ? "git+file://${toString ../.}?submodules=1",
  system ? builtins.currentSystem,
}:
let
  flake = builtins.getFlake flakeRef;
  pkgs = import flake.inputs.nixpkgs { inherit system; };
  build =
    zed:
    import ../packages/zed {
      inherit pkgs system;
      inputs = flake.inputs // {
        inherit zed;
      };
    };
  first = build flake.inputs.zed;
  second = build (
    flake.inputs.zed
    // {
      rev = "1111111111111111111111111111111111111111";
    }
  );
  # Change the checkout's store path without changing any Cargo inputs.
  documentationChange = build (
    flake.inputs.zed
    // {
      outPath = builtins.path {
        path = flake.inputs.zed.outPath;
        name = "source";
        filter = path: _type: path != "${flake.inputs.zed.outPath}/README.md";
      };
    }
  );
  # Inspect the artifacts consumed by the build, rather than upstream passthru.
  sameDependencies = first.drvAttrs.cargoArtifacts.drvPath == second.drvAttrs.cargoArtifacts.drvPath;
  differentApplications = first.drvPath != second.drvPath;
  sameDependenciesAfterSourceChange =
    first.drvAttrs.cargoArtifacts.drvPath == documentationChange.drvAttrs.cargoArtifacts.drvPath;
  matchingPassthru = first.cargoArtifacts.drvPath == first.drvAttrs.cargoArtifacts.drvPath;
  applicationMetadataPreserved =
    first.drvAttrs.ZED_COMMIT_SHA == flake.inputs.zed.rev
    && second.drvAttrs.ZED_COMMIT_SHA == "1111111111111111111111111111111111111111"
    && first.drvAttrs.RELEASE_VERSION == first.version
    && second.drvAttrs.RELEASE_VERSION == second.version;
in
assert builtins.pathExists (flake.inputs.zed.outPath + "/README.md");
assert sameDependencies;
assert differentApplications;
assert sameDependenciesAfterSourceChange;
assert matchingPassthru;
assert applicationMetadataPreserved;
{
  inherit
    sameDependencies
    differentApplications
    sameDependenciesAfterSourceChange
    matchingPassthru
    applicationMetadataPreserved
    ;
  dependencies = first.drvAttrs.cargoArtifacts.drvPath;
}
