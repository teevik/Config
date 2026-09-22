{ pkgs ? import ../packages/nix-lint/pkgs.nix }:
let
  intermediate = pkgs.runCommand "cache-warm-build-only" { } ''
    printf 'cache fixture\n' > "$out"
  '';
in
{
  result = pkgs.runCommand "cache-warm-result" { } ''
    # Copy the contents so the output has no runtime reference to its input.
    cat ${intermediate} > "$out"
  '';
  inherit intermediate;
  unbuilt = pkgs.runCommand "cache-warm-must-not-build" { } ''
    echo 'Cache inventory must not execute this builder' >&2
    exit 1
  '';
}
