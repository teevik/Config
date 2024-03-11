{ config, pkgs, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.healthchecks;
in
{
  options.teevik.services.healthchecks = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable healthchecks
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
    systemd.timers."healthchecks" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10m";
        OnUnitActiveSec = "10m";
        Unit = "healthchecks.service";
      };
    };

    systemd.services."healthchecks" = {
      script = ''
        ${lib.getExe pkgs.curl} https://hc-ping.com/$(cat ${config.age.secrets.healthchecks.path})/${cfg.slug}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
