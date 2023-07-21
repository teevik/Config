{ pkgs, lib, config, inputs, ... }:
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
      description = "Wayland wallpaper daemon";
      partOf = [ "graphical-session.target" ];
      script = "${lib.getExe pkgs.swaybg} -i ${./wallpaper.jpg} -m fill";
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
