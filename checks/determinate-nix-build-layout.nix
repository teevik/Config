{ perSystem, pkgs, ... }:
let
  buildDir = perSystem.self.determinate-nix.libs.nix-store.mesonBuildDir or "build";
in
pkgs.runCommand "determinate-nix-build-layout-check"
  {
    nativeBuildInputs = [
      pkgs.meson
      pkgs.ninja
      pkgs.stdenv.cc
    ];
  }
  ''
    # libstore has a source directory named build/. Meson's unity generator
    # must not mistake its files for generated files in the build directory.
    mkdir -p source/build
    printf '%s\n' 'int main() { return 0; }' > source/build/build-log.cc
    cat > source/meson.build <<'EOF'
    project('nix-store-build-layout', 'cpp')
    executable('probe', 'build/build-log.cc')
    EOF
    cd source
    meson setup ${pkgs.lib.escapeShellArg buildDir} -Dunity=on
    meson compile -C ${pkgs.lib.escapeShellArg buildDir}
    ${pkgs.lib.escapeShellArg "${buildDir}/probe"}
    touch "$out"
  ''
