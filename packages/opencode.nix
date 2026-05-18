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
    version = "1.15.4";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-aCoajfdfNsEq5YGFwX+YKkC6Bo19f34BbKt3wJ1FNmA=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-O6czNd9n6b0TTIsPseZn9qOlxsPzRTrePu3L6gM13oM=";
    });
  }
)
