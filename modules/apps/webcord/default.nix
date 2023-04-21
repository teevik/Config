{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      webcord
    ];
  };

  config.home = {
    xdg.desktopEntries.webcord = {
      name = "WebCord";
      genericName = "discord";
      exec = "webcord %U";
      startupNotify = true;
      categories = [ "Network" "InstantMessaging" ];
    };
  };
}
