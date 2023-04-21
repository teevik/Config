{
  pkgs,
  lib,
  ...
}: 
let
  wallpaper = builtins.fetchurl rec {
    name = "wallpaper-${sha256}.png";
    url = "https://cdn.discordapp.com/attachments/1098804407233151066/1098804441026662481/wallpaper-alt.jpg";
    sha256 = "0607yzkkhfagkvz9mk5b527a1l0nzq1d3bffzr3vrdcnxzicv8bb";
  };
in {
  systemd.user.services.swaybg = {
    description = "Wayland wallpaper daemon";
    partOf = ["graphical-session.target"];
    script = "${lib.getExe pkgs.swaybg} -i ${wallpaper} -m fill";
    wantedBy = ["graphical-session.target"];
  };
}
