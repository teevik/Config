# nix eval --impure --json --file tests/t3code-electron.nix
let
  pkgs = import ../packages/nix-lint/pkgs.nix;
  inherit (pkgs) lib;
  targets = import ../packages/update-targets.nix { };
  current = targets.t3code-nightly.unwrapped;

  # Exercise the package's real override boundary with a renamed upstream
  # argument and a lagging default alias. Older removed aliases must stay lazy.
  electron100 = pkgs.electron.overrideAttrs (_: {
    version = "100.0.0";
  });
  electronNames = builtins.filter (name: builtins.match "electron_[0-9]+" name != null) (
    builtins.attrNames pkgs
  );
  futurePkgs = builtins.removeAttrs pkgs electronNames // {
    electron_1 = throw "Removed Electron aliases must not be evaluated";
    electron_99 = pkgs.electron;
    electron_100 = electron100;
  };
  makeFuture =
    argument:
    import ../packages/t3code-nightly.nix {
      pkgs = futurePkgs;
      perSystem.llm-agents = {
        codex = null;
        claude-code = null;
        t3code = lib.makeOverridable (
          args:
          pkgs.stdenv.mkDerivation {
            pname = "t3code-electron-fixture";
            version = "1.0.0";
            pnpmWorkspaces = [ ];
            resourceMonitor = "/old-resource-monitor";
            preBuild = "Electron ${args.${argument}.version}";
            installPhase = "${args.${argument}}/bin/electron";
            meta = { };
          }
        ) { ${argument} = pkgs.electron; };
      };
    };
  renamed = makeFuture "electron_100";
  unversioned = makeFuture "electron";
in
assert lib.versionAtLeast current.electron.version "44.0.0";
assert lib.hasInfix "nix_major=${lib.versions.major current.electron.version}" current.preBuild;
assert lib.hasInfix (builtins.unsafeDiscardStringContext "${current.electron}/bin/electron")
  current.installPhase;
assert renamed.preBuild == "Electron 100.0.0";
assert renamed.installPhase == "${electron100}/bin/electron";
assert unversioned.preBuild == "Electron 100.0.0";
{
  currentRuntime = current.electron.version;
  latestMajorSelection = true;
  renamedArgument = true;
  unversionedArgument = true;
}
