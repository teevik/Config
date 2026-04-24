{ pkgs, ... }:
let
  inherit (pkgs) lib;
in
pkgs.opencode.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
    prettierPatch = pkgs.fetchpatch {
      name = "opencode-prettier-dep.patch";
      url = "https://github.com/anomalyco/opencode/pull/23255.diff";
      hash = "sha256-3Dt6UQaz3jPaDJWq83ZF7Cij45l4U15eiUfIQTvbaHY=";
    };
  in
  oldAttrs
  // rec {
    version = "1.14.22";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-T/Dk9Izh/DbbpY5fENJN4xFPMOUfKYNHGkuoY4HBpP0=";
    };
    patches = (old.patches or [ ]) ++ [ prettierPatch ];
    node_modules = old.node_modules.overrideAttrs (prev: {
      inherit src;
      patches = (prev.patches or [ ]) ++ [ prettierPatch ];
      # TODO: Remove when https://github.com/anomalyco/opencode/issues/23256 is fixed
      buildPhase = lib.replaceStrings [ "--frozen-lockfile \\\n  " ] [ "" ] prev.buildPhase;
      outputHash = "sha256-2+k0ioyhQCW0xSwfk9cvB5QCgEtjhaLINFZKKD65SD4=";
    });
  }
)
