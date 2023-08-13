{ config, pkgs, ... }:
let
  is-darwin = pkgs.stdenv.isDarwin;
  name = config.snowfallorg.user.name;
  home-directory =
    if is-darwin then
      "/Users/${name}"
    else
      "/home/${name}";
in
{
  home.username = name;
  home.homeDirectory = home-directory;

  systemd.user.startServices = "sd-switch";
}
