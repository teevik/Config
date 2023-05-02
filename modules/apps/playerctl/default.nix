{ pkgs, ... }:
{
  teevik.home = {
    services.playerctld.enable = true;
  };

  environment.systemPackages = with pkgs; [
    playerctl
  ];
}
