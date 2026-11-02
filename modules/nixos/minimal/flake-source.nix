# Share the source boundary between the registry and optional cached rebuilds.
# Include directories used by modules, packages, and checks as the flake grows.
{
  lib,
  root ? ../../..,
}:
lib.fileset.toSource {
  inherit root;
  fileset = lib.fileset.unions [
    (root + "/.github")
    (root + "/flake.nix")
    (root + "/flake.lock")
    (root + "/formatter.nix")
    (root + "/checks")
    # Hjem lists this tree at evaluation time to build the symlink set.
    (root + "/dotfiles")
    (root + "/hosts")
    (root + "/modules")
    (root + "/packages")
    # Absent while no nixpkgs patches are pending.
    (lib.fileset.maybeMissing (root + "/patches"))
    (root + "/scripts")
    (root + "/tests")
  ];
}
