{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libnotify
  ];

  teevik.home = {
    services.mako = {
      enable = true;
    };
  };
}
