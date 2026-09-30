{ pkgs, perSystem, ... }:
let
  # Exercise our grammar overrides with the host toolchain without compiling
  # the Helix application or every other language grammar.
  helix = import ../packages/helix.nix {
    inherit pkgs;
    perSystem.helix.default = perSystem.helix.default.override {
      includeGrammarIf = grammar: grammar.name == "perl";
    };
  };
in
pkgs.runCommand "helix-perl-grammar-check" { } ''
  test -s ${helix.HELIX_DEFAULT_RUNTIME}/grammars/perl${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
  touch "$out"
''
