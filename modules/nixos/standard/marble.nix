{
  perSystem,
  pkgs,
  ...
}:
{
  systemd.user.services.marble = {
    description = "Marble Shell";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${perSystem.marble.default}/bin/marble";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      KillMode = "mixed";
    };
  };
}
