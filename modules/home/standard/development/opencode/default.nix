{
  flake,
  perSystem,
  config,
  ...
}:
{
  programs.opencode = {
    enable = true;
    # HACK: remove if not needed
    package = perSystem.opencode.default.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # Relax bun version requirement (upstream flake pins an older bun)
        substituteInPlace packages/script/src/index.ts \
          --replace-fail 'const expectedBunVersionRange = `^''${expectedBunVersion}`' \
                         'const expectedBunVersionRange = `>=0.0.0`'
      '';
    });
  };

  xdg.configFile = {
    "opencode/config.json".source =
      flake.lib.symlinkToConfig config "modules/home/standard/development/opencode/opencode.json";
  };

  xdg.configFile = {
    "opencode/oh-my-opencode.json".source =
      flake.lib.symlinkToConfig config "modules/home/standard/development/opencode/oh-my-opencode.json";
  };
}
