{
  flake,
  config,
  pkgs,
  lib,
  ...
}:
let
  pathFor = file: "modules/home/standard/apps/spotify/" + file;
in
{
  # HACK: Spotify is only available on x86_64-linux
  home.packages = lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
    pkgs.spotify
  ];

  xdg.configFile."spotify/Users/vikoren123-user/prefs" = {
    source = flake.lib.symlinkToConfig config (pathFor "prefs");
    force = true;
  };
}
