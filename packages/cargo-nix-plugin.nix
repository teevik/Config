{
  inputs,
  perSystem,
  pkgs,
  ...
}:
# The upstream flake builds against nixpkgs' nixVersions, but the plugin ABI
# only works with the exact Nix it was compiled against. Build it against the
# Determinate Nix components that `nix.package` uses instead.
pkgs.callPackage "${inputs.cargo-nix-plugin}/nix/plugin.nix" {
  nixComponents = {
    inherit (perSystem.determinate-nix) nix-expr nix-store;
  };
}
