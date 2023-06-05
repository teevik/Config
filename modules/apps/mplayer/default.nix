{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mplayer
  ];
}
