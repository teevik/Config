{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.autologin;
in
{
  options.teevik.services.autologin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable autologin
      '';
    };
  };

  config = mkIf cfg.enable {
    services.getty.autologinUser = "teevik";

    environment.loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ]; then
        Hyprland
      fi
    '';
  };
}
