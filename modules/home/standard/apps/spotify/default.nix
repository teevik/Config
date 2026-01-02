{
  flake,
  config,
  pkgs,
  ...
}:
let
  pathFor = file: "modules/home/standard/apps/spotify/" + file;
in
{
  home.packages = with pkgs; [
    spotify
  ];

  xdg.configFile."spotify/Users/vikoren123-user/prefs" = {
    source = flake.lib.symlinkToConfig config (pathFor "prefs");
    force = true;
  };
}
