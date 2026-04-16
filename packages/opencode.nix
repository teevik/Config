{ pkgs, ... }:
pkgs.opencode.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
  in
  oldAttrs
  // rec {
    version = "1.4.3";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-m+Ue7FWiTjKMAn1QefAwOMfOb2Vybk0mJPV9zcbkOmE=";
    };
    patches = (old.patches or [ ]) ++ [
      ./opencode-terminal-title.patch
    ];
    node_modules = old.node_modules.overrideAttrs {
      inherit src;
      outputHash = "sha256-hVXlQcUuvUudIB35Td6ucBYopM/QOSx59tQbCTqoB/0=";
    };
  }
)
