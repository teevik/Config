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
    version = "1.15.0";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-qVkOgLXUU/vaWDZIkBeR3Fhkcz7cPshpyQIkuxwKUEM=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-mozaLyyHm7fO6XYTrEMb1in0LNtA4BXZAowJ+8UMh7Q=";
    });
  }
)
