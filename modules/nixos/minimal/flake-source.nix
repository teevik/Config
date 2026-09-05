# Share the source boundary between the registry and optional cached rebuilds.
# Include new Nix source directories here if the flake grows any.
{
  lib,
  root ? ../../..,
}:
lib.fileset.toSource {
  inherit root;
  fileset = lib.fileset.unions [
    (root + "/flake.nix")
    (root + "/flake.lock")
    (root + "/formatter.nix")
    (root + "/checks")
    (root + "/hosts")
    (root + "/modules")
    (root + "/packages")
    (root + "/templates")
    (root + "/tests")
  ];
}
