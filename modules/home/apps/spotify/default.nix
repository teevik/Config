{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.spotify;
  theme = config.teevik.theme.spicetifyTheme;
  spicePkgs = inputs.spicetify.legacyPackages.${pkgs.system};
in
{
  options.teevik.apps.spotify = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable spotify
      '';
    };
  };

  imports = [ inputs.spicetify.homeManagerModules.default ];

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      theme = mkIf (theme.theme != null) spicePkgs.themes.${theme.theme};
      colorScheme = theme.colorScheme;
      customColorScheme = theme.customColorScheme;

      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        groupSession
        powerBar
        beautifulLyrics
        playingSource
        betterGenres
        history
      ];
    };

    xdg.configFile = {
      "spotify/Users/vikoren123-user/prefs".text = ''
        audio.play_bitrate_non_metered_migrated=true
        ui.track_notifications_enabled=false
      '';
    };
  };
}
