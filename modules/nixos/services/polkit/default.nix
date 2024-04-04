{ config, pkgs, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.polkit;
in
{
  options.teevik.services.polkit = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable polkit
      '';
    };

    slug = mkOption {
      type = types.str;
      description = ''
        The slug of the server
      '';
    };
  };

  config = mkIf cfg.enable {
    security.polkit.enable = true;
    programs.dconf.enable = true;

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        enable = true;

        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
