{ inputs, system, ... }:
let
  # Preserve both flakes' locked sources and dependency sets, including
  # Zed's own nixpkgs, so the upstream binary cache remains usable.
  withInputs =
    flake: overrides:
    let
      inputs = flake.inputs // overrides;
      outputs = (import (flake.outPath + "/flake.nix")).outputs (inputs // { self = result; });
      result = flake // outputs // { inherit inputs outputs; };
    in
    result;
  upstream = inputs.zed.inputs.zed;
  zed = withInputs inputs.zed {
    zed = withInputs upstream {
      crane = import ./crane.nix upstream.inputs.crane;
    };
  };
in
zed.packages.${system}.default
