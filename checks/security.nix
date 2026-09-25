{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../.github
      ../packages/security
      ../tests/security.py
      ../tests/cache-upload.py
      ../tests/cache-bootstrap.py
      ../tests/cache-shared.py
      ../modules/nixos/minimal/homelab-cache.pub
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
      pkgs.nix.out
    ];
  }
  ''
    cd ${source}
    python3 tests/security.py
    python3 tests/cache-upload.py
    python3 tests/cache-bootstrap.py
    python3 tests/cache-shared.py
    actionlint -oneline .github/workflows/*.yml
    touch "$out"
  ''
