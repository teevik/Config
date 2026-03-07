{ pkgs, perSystem, ... }:
let
  opencode = perSystem.self.opencode;
in
(pkgs.opencode-desktop.override {
  inherit opencode;
}).overrideAttrs
  (old: {
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit (opencode) src;
      sourceRoot = "${opencode.src.name}/packages/desktop/src-tauri";
      hash = "sha256-WI48iYdxmizF1YgOQtk05dvrBEMqFjHP9s3+zBFAat0=";
    };
  })
