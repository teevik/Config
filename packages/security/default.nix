{ pkgs ? import ../nix-lint/pkgs.nix, ... }:
let
  # This revision supports NixOS toplevel metadata and mandatory CPE data.
  # Keep the caller's Nix first on PATH: its Cargo plugin requires that ABI.
  sbomnix = pkgs.sbomnix.overridePythonAttrs (old: {
    version = "1.8.0-unstable-2026-09-18";
    # Keep the archive compressed in the fixed-output fetch: upstream's docs
    # contain literal store paths, which cannot be references of a fetch output.
    src = pkgs.fetchurl {
      url = "https://github.com/tiiuae/sbomnix/archive/f3c241a49b27af9774894ad3cfb250d4d87280d8.tar.gz";
      hash = "sha256-vJ1awtmKUNHpbtQsHqlRvo8V2F1KrwptPfMP5SHsLbE=";
    };
    dependencies = old.dependencies ++ [ pkgs.python3Packages.license-expression ];
    makeWrapperArgs = [ "--suffix PATH : ${pkgs.lib.makeBinPath [ pkgs.git ]}" ];
  });
in
pkgs.writeShellApplication {
  name = "nix-security-scan";
  runtimeInputs = [
    sbomnix
    pkgs.grype
    pkgs.age
    pkgs.python3
  ];
  text = ''
    exec python3 ${./scan.py} "$@"
  '';
}
