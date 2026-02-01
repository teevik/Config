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
    # perSystem.zed.default
  ];

  home.file.".zed_server" = {
    source = "${pkgs.zed-editor}/bin";
    recursive = true;
  };

  xdg.configFile = {
    "zed/settings.json".source = flake.lib.symlinkToConfig config (pathFor "settings.json");
    "zed/keymap.json".source = flake.lib.symlinkToConfig config (pathFor "keymap.json");
  };
}
