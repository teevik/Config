# Exercise Zotero's actual runtime patch without rebuilding the application.
# nix build .#zotero.tests.runtime --no-link --print-build-logs
{
  pkgs,
  zoteroSource,
  firefoxRuntime,
}:
pkgs.runCommand "zotero-runtime-check"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.unzip
      pkgs.perl
    ];
  }
  ''
    cp ${firefoxRuntime}/lib/firefox/omni.ja .
    chmod u+w omni.ja
    python3 ${zoteroSource}/app/scripts/optimizejars.py --deoptimize . . .
    unzip -q omni.ja modules/ActorManagerParent.sys.mjs

    source ${zoteroSource}/app/scripts/utils.sh
    remove_between 'AboutTranslations: \{' '^  },' modules/ActorManagerParent.sys.mjs
    touch "$out"
  ''
