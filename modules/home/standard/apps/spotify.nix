{ pkgs, ... }:
{
  home.packages = with pkgs; [
    spotify
  ];

  xdg.configFile."spotify/Users/vikoren123-user/prefs".text = ''
    audio.play_bitrate_non_metered_migrated=true
    ui.track_notifications_enabled=false
  '';
}
