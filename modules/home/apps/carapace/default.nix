{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.carapace;
in
{
  options.teevik.apps.carapace = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable carapace
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.carapace = {
      enable = true;

      # enableBashIntegration = false;
      # enableFishIntegration = false;
      # enableNushellIntegration = false;
    };
  };
}
