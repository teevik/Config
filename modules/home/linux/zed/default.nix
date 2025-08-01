{
  flake,
  config,
  pkgs,
  ...
}:
let
  pathFor = file: "modules/home/linux/zed/" + file;
in
{
  home.packages = [
    pkgs.zed-editor
  ];

  xdg.configFile = {
    "zed/settings.json".source = flake.lib.symlinkToConfig config (pathFor "settings.json");
    "zed/keymap.json".source = flake.lib.symlinkToConfig config (pathFor "keymap.json");
  };
}
