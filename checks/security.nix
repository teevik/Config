{ pkgs ? import ../packages/nix-lint/pkgs.nix, ... }:
let
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../.github
      ../packages/security
      ../tests/security.py
    ];
  };
in
pkgs.runCommand "security-check"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.age
      pkgs.actionlint
      pkgs.shellcheck
    ];
  }
  ''
    cd ${source}
    python3 tests/security.py
    actionlint -oneline .github/workflows/*.yml
    touch "$out"
  ''
