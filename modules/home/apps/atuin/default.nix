{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.atuin;
in
{
  options.teevik.apps.atuin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable atuin
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      settings = {
        key_path = config.age.secrets.atuin.path;
        sync_frequency = "15m";

        enableBashIntegration = false;
        enableFishIntegration = false;
        enableNushellIntegration = false;
      };
    };
  };
}
