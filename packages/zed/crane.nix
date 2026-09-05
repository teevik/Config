crane:
let
  # Compare only as far as the first mismatch. Crane checks these short
  # prefixes for every field in every workspace Cargo.toml; constructing
  # a sublist for each comparison adds substantial evaluator allocation.
  hasPrefix =
    prefix: list:
    prefix == [ ]
    || (
      list != [ ]
      && builtins.head prefix == builtins.head list
      && hasPrefix (builtins.tail prefix) (builtins.tail list)
    );
in
crane
// {
  mkLib =
    pkgs:
    (crane.mkLib pkgs).overrideScope (
      _final: prev: {
        filters = prev.filters // {
          # Keep upstream's removal rules, changing only prefix matching.
          cargoTomlConservative = import (crane.outPath + "/lib/filters/cargoTomlConservative.nix") {
            lib = pkgs.lib // {
              lists = pkgs.lib.lists // {
                inherit hasPrefix;
              };
            };
          };
        };

        downloadCargoPackageFromGit =
          args:
          let
            ref = args.ref or null;
            allRefs = args.allRefs or (ref == null);
          in
          prev.downloadCargoPackageFromGit (
            args
            // pkgs.lib.optionalAttrs (ref == null && allRefs) {
              # Cargo.lock pins the commit; don't resolve remote HEAD.
              ref = args.rev;
              allRefs = true;
            }
          );
      }
    );
}
