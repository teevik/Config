{
  pkgs ? import ./pkgs.nix,
  ...
}:
(import ../nu-scripts/write-application.nix { inherit pkgs; }) {
  name = "nix-lint";
  runtimeInputs = with pkgs; [
    statix
    deadnix
  ];
  runtimeEnv.STATIX_CONFIG = ./statix.toml;
  script = ./lint.nu;
}
