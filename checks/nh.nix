{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  nh = import ../packages/nh { inherit pkgs; };
  checkout = "/tmp/nh-source-hook-checkout";
  configuredNh = import ../packages/nh {
    inherit pkgs;
    flake = checkout;
  };
in
pkgs.runCommand "nh-source-hook-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 ${../tests/nh-source-hook.py} ${pkgs.lib.getExe nh} ${pkgs.lib.getExe configuredNh} ${checkout}
  touch "$out"
''
