{ pkgs, ... }:
pkgs.opencode.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
  in
  oldAttrs
  // rec {
    version = "1.4.6";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-rVbWlVY4ujNVaE1o3SJmD0NrfWDtAfH+8MhOzmGgnhM=";
    };
    node_modules = old.node_modules.overrideAttrs {
      inherit src;
      outputHash = "sha256-0vIkCiVnyy3FwXWI3ZooskJGMhEI75BP9Xc/ZLWaTbk=";
    };
  }
)
