{ pkgs ? import ../packages/nix-lint/pkgs.nix, ... }:
let
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../.github
      ../packages/security
      ../tests/security.py
      ../tests/cache-upload.py
      ../tests/nixbuild-ssh.py
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
      pkgs.openssh
    ];
  }
  ''
    cd ${source}
    python3 tests/security.py
    python3 tests/cache-upload.py
    python3 tests/nixbuild-ssh.py
    shellcheck .github/actions/nixbuild/daemon-ssh.sh
    actionlint -oneline .github/workflows/*.yml
    touch "$out"
  ''
