{
  inputs,
  pkgs,
  ...
}:
let
  runtimePkgs = import inputs.nixpkgs-zotero-runtime {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  firefoxRuntime = runtimePkgs.firefox-esr-140-unwrapped;
  # Support both the committed lock and the next nightly nixpkgs update.
  zotero = pkgs.zotero.override (
    builtins.intersectAttrs (pkgs.lib.functionArgs pkgs.zotero.override) {
      firefox-esr-140-unwrapped = firefoxRuntime;
      firefox-esr-153-unwrapped = firefoxRuntime;
    }
  );
in
zotero.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit firefoxRuntime;
    tests = (old.passthru.tests or { }) // {
      build-with-checks = zotero.override { doCheck = true; };
      runtime = import ../tests/zotero-runtime.nix {
        inherit pkgs firefoxRuntime;
        zoteroSource = zotero.src;
      };
    };
  };
})
