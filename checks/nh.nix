{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  nh = import ../packages/nh { inherit pkgs; };
in
pkgs.runCommand "nh-source-hook-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 ${../tests/nh-source-hook.py} ${pkgs.lib.getExe nh}
  touch "$out"
''
