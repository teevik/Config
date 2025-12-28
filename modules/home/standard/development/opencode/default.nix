{
  flake,
  perSystem,
  config,
  ...
}:
{
  programs.opencode = {
    enable = true;
    package = perSystem.opencode.default;
  };

  xdg.configFile = {
    "opencode/config.json".source =
      flake.lib.symlinkToConfig config "modules/home/standard/development/opencode/opencode.json";
  };
}
