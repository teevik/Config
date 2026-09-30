{ pkgs, perSystem, ... }:

# The pinned upstream grammar builder still reads deprecated stdenv.isLinux.
# Keep its strip phase identical using the current platform API, so
# unaffected grammar derivations remain unchanged.
perSystem.helix.default.override {
  grammarOverlays = [
    (
      _final: prev:
      pkgs.lib.mapAttrs (
        name: grammar:
        if pkgs.lib.isDerivation grammar then
          grammar.overrideAttrs (
            old:
            {
              fixupPhase = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                runHook preFixup
                $STRIP $out/$SHARED_LIB
                runHook postFixup
              '';
            }
            // pkgs.lib.optionalAttrs (name == "perl") {
              # glibc's C23 bsearch macro must not expand the grammar's bundled
              # function definition. Parenthesizing its name preserves the ABI.
              postPatch = (old.postPatch or "") + ''
                substituteInPlace src/bsearch.c \
                  --replace-fail 'void *bsearch(' 'void *(bsearch)('
              '';
            }
          )
        else
          grammar
      ) prev
    )
  ];
}
