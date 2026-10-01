# nix build --impure --no-link --file tests/t3code-native.nix
{
  packageRoot ? null,
}:
let
  pkgs = import ../packages/nix-lint/pkgs.nix;
  t3code = (import ../packages/update-targets.nix { }).t3code-nightly.unwrapped;
in
pkgs.runCommand "t3code-native-check"
  {
    T3CODE_PACKAGE_ROOT = if packageRoot == null then "${t3code}" else builtins.storePath packageRoot;
    T3CODE_TEST_SHELL = pkgs.stdenv.shell;
  }
  ''
    env -u LD_LIBRARY_PATH ELECTRON_RUN_AS_NODE=1 \
      ${pkgs.lib.getExe t3code.electron} ${./t3code-native.cjs}
    touch "$out"
  ''
