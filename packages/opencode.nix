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
    version = "1.15.7";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-fk8GDVE+bQfOkZCQ1YEc3V7YIXDHfNC/srcZs/MrE38=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-bwCWjaIYfzkJkCMRQ8veKM81pBt8CzMZhUqHgFM/muk=";
    });
  }
)
