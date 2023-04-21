{
  pkgs,
  lib,
  ...
}: 
let
  wallpaper = builtins.fetchurl rec {
    name = "wallpaper-${sha256}.png";
    url = "https://images.unsplash.com/photo-1567095716798-1d95d8f4c479?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8";
    sha256 = "1x9y9rzqb9mpxc5lmgvc7jxqdyn3j7ryv16vn5lx6qrhpwp24kym";
  };
in {
  systemd.user.services.swaybg = {
    description = "Wayland wallpaper daemon";
    partOf = ["graphical-session.target"];
    script = "${lib.getExe pkgs.swaybg} -i ${wallpaper} -m fill";
    wantedBy = ["graphical-session.target"];
  };
}
