{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.webcord;
  discordTheme = config.teevik.theme.discordTheme;
in
{
  options.teevik.apps.webcord = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable webcord
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      webcord
    ];

    xdg.configFile =
      {
        "WebCord/config.json".source = ./config.json;

        "WebCord/Themes/theme" = mkIf (discordTheme != null) {
          source = discordTheme;
        };
      };
  };
}
