{
  perSystem,
  pkgs,
  ...
}:
# Determinate Nix with local optimizations
(perSystem.determinate-nix.default.appendPatches [
  ./slop-optimizations.patch
]).overrideAllMesonComponents
  (
    _: old:
    pkgs.lib.optionalAttrs (old.pname == "determinate-nix-store") {
      # libstore's build/ contains source files. Meson 1.12 unity builds confuse
      # those with generated files when the build directory has the same name.
      mesonBuildDir = "_build";
    }
    // pkgs.lib.optionalAttrs (old.pname == "determinate-nix-util") {
      patches = (old.patches or [ ]) ++ [ ./boost-url-zone-id.patch ];
      postPatch = (old.postPatch or "") + ''
        chmod u+w ../../nix-meson-build-support/common/cxa-throw \
          ../../nix-meson-build-support/common/cxa-throw/interpose-cxa-throw.cc
        patch -d ../.. -p1 < ${./cxx-runtime-lookup.patch}
      '';
    }
  )
