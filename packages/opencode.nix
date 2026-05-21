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
    version = "1.15.6";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-neISh7Gs1y8+2M0/5erhhNip5ZBYlUFqbgOsVljZ2Gc=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-IPht2Pf4q6qIDz8zMC27d9m3cdi0qzD1a4tLTISnE6E=";
    });
  }
)
