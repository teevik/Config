{ lib, config, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.i3;
in
{
  options.teevik.desktop.i3 = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable i3
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xorg.xinit
      xorg.xauth
    ];

    services.xserver = {
      enable = true;

      displayManager = {
        defaultSession = "none+i3";
        startx.enable = true;
      };

      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;

        extraPackages = with pkgs; [
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
        ];
      };
    };
  };
}
