{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.yazi;

  font = "JetBrainsMono Nerd Font";
  opacity = 0.2;
  size = 13;
in
{
  options.teevik.apps.yazi = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable yazi
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
