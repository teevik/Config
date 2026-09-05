# Standalone entry points need only the existing locked nixpkgs, not the
# private flake inputs or Blueprint's package/host discovery. Blueprint
# supplies its existing pkgs instead, so this default stays lazy there.
let
  lock = builtins.fromJSON (builtins.readFile ../../flake.lock);
  locked = lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked;
in
import (builtins.fetchTree locked) { }
