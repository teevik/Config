# nix eval --impure --json --expr 'import ./tests/zed-cargo-nix.nix {}'
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
  original = build flake.inputs.zed;
  changed = build (
    flake.inputs.zed
    // {
      rev = "1111111111111111111111111111111111111111";
      outPath = builtins.path {
        path = flake.inputs.zed.outPath;
        name = "source";
        filter = path: _type: path != "${flake.inputs.zed.outPath}/README.md";
      };
    }
  );
  graph = original.cargoNix.resolved;
  sourceChanged = build (
    flake.inputs.zed
    // {
      outPath = builtins.path {
        path = flake.inputs.zed.outPath;
        name = "source";
        filter = path: _type: path != "${flake.inputs.zed.outPath}/crates/util/src/util.rs";
      };
    }
  );
  productionFeatures =
    builtins.all (name: !(builtins.elem "test-support" graph.crates.${name}.resolvedDefaultFeatures))
      [
        "gpui"
        "editor"
        "project"
      ];
  cached = package: name: package.cargoNix.builtCrates.cratesLibOnly.${name}.drvPath;
  registryCacheReused = cached original "serde" == cached changed "serde";
  workspaceCacheReused = cached original "util" == cached changed "util";
  workspaceSourceTracked = cached original "util" != cached sourceChanged "util";
  registryCacheIndependent = cached original "serde" == cached sourceChanged "serde";
  applicationRebuilt =
    original.cargoNix.workspaceMembers.zed.build.drvPath
    != changed.cargoNix.workspaceMembers.zed.build.drvPath;
in
assert builtins.pathExists (flake.inputs.zed.outPath + "/README.md");
assert original.cargoNix.apiLevel == original.cargoNix.resolverApiLevel;
assert graph.crates.scratch.source.type == "local";
assert productionFeatures;
assert registryCacheReused;
assert workspaceCacheReused;
assert workspaceSourceTracked;
assert registryCacheIndependent;
assert applicationRebuilt;
{
  inherit
    productionFeatures
    registryCacheReused
    workspaceCacheReused
    workspaceSourceTracked
    registryCacheIndependent
    applicationRebuilt
    ;
  roots = builtins.attrNames original.cargoNix.workspaceMembers;
}
