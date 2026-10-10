# nix build --file tests/lint-checks.nix --no-link --print-build-logs
#
# Every checks/*.nix file, built the same way Blueprint exposes it as
# checks.<system>.<name>. Lint builds this rather than running
# `nix flake check`, which would discover every Blueprint package/host and
# fetch private flake inputs. Kept outside checks/ so Blueprint does not load
# it as a check.
let
  pkgs = import ../packages/nix-lint/pkgs.nix;
  inherit (pkgs) lib;
  files = lib.filterAttrs (name: type: type != "directory" && lib.hasSuffix ".nix" name) (
    builtins.readDir ../checks
  );
in
lib.mapAttrs' (file: _: {
  name = lib.removeSuffix ".nix" file;
  value = import (../checks + "/${file}") { inherit pkgs; };
}) files
