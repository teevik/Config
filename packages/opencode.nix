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
    version = "1.14.33";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-bnAV1ApOYZngG59fxFKrGN0jmBKWKnjktsbKJiEOaSo=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      # TODO: Remove when https://github.com/anomalyco/opencode/issues/23256 is fixed
      buildPhase = lib.replaceStrings [ "--frozen-lockfile \\\n  " ] [ "" ] prev.buildPhase;
      outputHash = "sha256-dbpqhVcjWr+puZhV0x7pR38iMjjZdbrJydKJ/qJfDeY=";
    });
  }
)
