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
    version = "1.15.10";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-qp67k8Z+VA81uukZYuu3yqqmg/L8pkxYZQrJBoE25tU=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-r3S0HHNk4TeTHEd8vbvgF+AXl5lJAyrTq+u2T3W0PdA=";
    });
  }
)
