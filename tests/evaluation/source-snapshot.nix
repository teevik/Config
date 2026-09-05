# Prepare a stable flake reference before asking Nix to evaluate the system.
# Only this cheap preparation is impure; the subsequent flake build stays pure.
let
  source = builtins.fetchTree {
    type = "git";
    url = "file://${toString ../..}";
    submodules = true;
  };
  root = /. + builtins.unsafeDiscardStringContext source.outPath;
  lock = builtins.fromJSON (builtins.readFile (root + "/flake.lock"));
  locked = lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked;
  lib = import ((builtins.fetchTree locked).outPath + "/lib");
in
toString (import (root + "/modules/nixos/minimal/flake-source.nix") { inherit lib root; })
