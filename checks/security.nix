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
      ../packages/update-packages.json
      ../modules/nixos/minimal/install-seed.sh
      ../tests/security.py
      ../tests/cache-upload.py
      ../tests/cache-hosts.py
      ../tests/cache-update.py
      ../tests/pr-body.py
      ../modules/nixos/minimal/homelab-cache.pub
      ../modules/nixos/minimal/trusted-public-keys.txt
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
      pkgs.git
    ];
  }
  ''
    cd ${source}
    python3 tests/security.py
    python3 tests/cache-upload.py
    python3 tests/cache-hosts.py
    python3 tests/cache-update.py
    python3 tests/pr-body.py
    shellcheck .github/ci/host.sh
    shellcheck .github/ci/check.sh
    shellcheck .github/ci/notify-failure.sh
    shellcheck .github/ci/setup-env.sh
    shellcheck .github/ci/free-disk-space.sh
    shellcheck .github/ci/check-cache-config.sh
    shellcheck .github/ci/security-tools.sh
    shellcheck .github/ci/update-packages.sh
    shellcheck .github/ci/nix-conf.sh
    shellcheck modules/nixos/minimal/install-seed.sh
    actionlint -oneline .github/workflows/*.yml
    touch "$out"
  ''
