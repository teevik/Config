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
    version = "1.14.50";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-SMWJb0Ykxklnh8DQ6UcSv1JIeuqK2qKyUgrwB8ioZCI=";
    };
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      outputHash = "sha256-gEgvlufMz8nsG7xoBqs/GFMTo88Rz6yfqBWhxJM8Iz0=";
    });
  }
)
