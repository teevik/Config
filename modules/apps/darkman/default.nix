{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.darkman;

  package = pkgs.darkman;
  yamlFormat = pkgs.formats.yaml { };
  settings = {
    usegeoclue = false;
  };
in
{
  options.teevik.apps.darkman = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable darkman
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      home.packages = [ package ];

      xdg.configFile."darkman/config.yaml".source =
        (yamlFormat.generate "darkman-config.yaml" settings);

      systemd.user.services.darkman = {
        Unit = {
          Description = "Darkman system service";
          Documentation = "man:darkman(1)";
          PartOf = [ "graphical-session.target" ];
          BindsTo = [ "graphical-session.target" ];
        };

        Service = {
          Type = "dbus";
          BusName = "nl.whynothugo.darkman";
          ExecStart = "${package}/bin/darkman run";
          # Scripts are started with `bash` instead of just `sh`
          Environment = "PATH=${lib.makeBinPath [ pkgs.bash ]}";
          Restart = "on-failure";
          TimeoutStopSec = 15;
          Slice = "background.slice";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
