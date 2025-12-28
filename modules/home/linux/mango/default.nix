{
  flake,
  inputs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  enabled = osConfig.programs.mango.enable;
in
{
  imports = [
    inputs.mango.hmModules.mango
  ];

  config = mkIf enabled {
    wayland.windowManager.mango = {

      enable = true;
      systemd.enable = true;
    };

    xdg.configFile = {
      "mango/config.conf".source =
        flake.lib.symlinkToConfig config "modules/home/linux/mango/config.conf";
    };
  };
}
