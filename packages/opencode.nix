{ pkgs, ... }:
let
  inherit (pkgs) lib;
in
pkgs.opencode.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
  in
  oldAttrs
  // rec {
    version = "1.14.28";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-lsyjM6rhSv1HzEd2d/+aGHqrYMARj+TrFrLMGY2X59U=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      # TODO: Remove when https://github.com/anomalyco/opencode/issues/23256 is fixed
      buildPhase = lib.replaceStrings [ "--frozen-lockfile \\\n  " ] [ "" ] prev.buildPhase;
      outputHash = "sha256-shMfcEeS4T/gUKILrXmFTnXISg4CcL682YniuaNlb2I=";
    });
  }
)
