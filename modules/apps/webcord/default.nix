{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    webcord
  ];

  teevik.home = {
    xdg.desktopEntries.webcord = {
      name = "WebCord";
      genericName = "discord";
      exec = "webcord %U";
      startupNotify = true;
      categories = [ "Network" "InstantMessaging" ];
    };
  };
}
