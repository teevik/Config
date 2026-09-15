{
  perSystem,
  pkgs,
  ccacheDir ? "/var/cache/ccache",
  ...
}:
perSystem.hyprland.hyprland.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.ccache ];
  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
    "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
  ];
  preConfigure = (old.preConfigure or "") + ''
    export CCACHE_DIR=${pkgs.lib.escapeShellArg (toString ccacheDir)}
    export CCACHE_UMASK=007
    # Match NixOS's ccache wrapper: Nix changes this seed with the output path.
    export CCACHE_SLOPPINESS=random_seed
    # Cache workers and other builders can compile the same derivation even
    # when they do not expose a persistent compiler cache in their sandbox.
    if [ ! -w "$CCACHE_DIR" ]; then
      export CCACHE_DISABLE=1
    fi
  '';
})
