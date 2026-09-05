{ pkgs, perSystem, ... }:

# The pinned upstream grammar builder still reads deprecated stdenv.isLinux.
# Override only its strip phase using the current platform API. The phase
# text and resulting derivations stay identical; no source patch or extra
# nixpkgs import is needed. Remove once upstream grammars.nix is migrated.
perSystem.helix.default.override {
  grammarOverlays = [
    (
      _final: prev:
      pkgs.lib.mapAttrs (
        _: grammar:
        if pkgs.lib.isDerivation grammar then
          grammar.overrideAttrs {
            fixupPhase = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              runHook preFixup
              $STRIP $out/$SHARED_LIB
              runHook postFixup
            '';
          }
        else
          grammar
      ) prev
    )
  ];
}
