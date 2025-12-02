{
  flake,
  config,
  pkgs,
  perSystem,
  ...
}:
let
  pathFor = file: "modules/home/linux/zed/" + file;
in
{
  home.packages = [
    # pkgs.zed-editor
    perSystem.zed.default
  ];

  xdg.configFile = {
    "zed/settings.json".source = flake.lib.symlinkToConfig config (pathFor "settings.json");
    "zed/keymap.json".source = flake.lib.symlinkToConfig config (pathFor "keymap.json");
  };
}
