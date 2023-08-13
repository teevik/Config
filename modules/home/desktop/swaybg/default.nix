{ pkgs, lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.swaybg;
in
{
  options.teevik.desktop.swaybg = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable swaybg
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.swaybg = {
      Unit = {
        Description = "Wayland wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.swaybg} -i ${config.teevik.theme.background} -m fill";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
