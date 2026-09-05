{
  pkgs ? import ./pkgs.nix,
  ...
}:
pkgs.writeShellApplication {
  name = "nix-lint";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    statix
    deadnix
  ];
  text = ''
    statix_config=${./statix.toml}
  ''
  + builtins.readFile ./lint.sh;
}
