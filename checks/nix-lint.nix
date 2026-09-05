{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  lint = import ../packages/nix-lint { inherit pkgs; };
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset =
      pkgs.lib.fileset.intersection (pkgs.lib.fileset.fileFilter (file: file.hasExt "nix") ../.)
        (
          pkgs.lib.fileset.unions [
            ../flake.nix
            ../formatter.nix
            ../checks
            ../hosts
            ../modules
            ../packages
            ../templates
            ../tests
          ]
        );
  };
in
pkgs.runCommand "nix-lint-check" { nativeBuildInputs = [ lint ]; } ''
  nix-lint ${source}
  bash ${../tests/nix-lint.sh} ${pkgs.lib.getExe lint} ${../tests/lint-fixtures}
  touch "$out"
''
