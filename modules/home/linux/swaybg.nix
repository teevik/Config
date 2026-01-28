{
  pkgs,
  lib,
  config,
  ...
}:
{
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.swaybg} -i ${config.teevik.theme.background} -m fill";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
