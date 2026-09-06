{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  writeNuApplication = import ../packages/nu-scripts/write-application.nix { inherit pkgs; };
  guard = writeNuApplication {
    name = "cachix-safe-hook";
    script = ../tests/cachix-safe-hook.nu;
  };
  store = writeNuApplication {
    name = "mock-nix-store";
    script = ../tests/cachix-privacy-fixtures/store.nu;
  };
  upload = writeNuApplication {
    name = "mock-upload";
    script = ../tests/cachix-privacy-fixtures/upload.nu;
  };
  boundGuard = import ../tests/cachix-hook.nix {
    inherit pkgs;
    originalHook = pkgs.lib.getExe upload;
    nixStoreBin = pkgs.lib.getExe store;
  };
in
pkgs.runCommand "cachix-privacy-check" { } ''
  ${pkgs.lib.getExe pkgs.nushell} --no-config-file ${../tests}/cachix-privacy.nu \
    ${pkgs.lib.getExe guard} ${pkgs.lib.getExe store} ${pkgs.lib.getExe upload} \
    ${pkgs.lib.getExe boundGuard}
  touch "$out"
''
