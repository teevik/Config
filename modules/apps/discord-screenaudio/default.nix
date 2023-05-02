{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.teevik.discord-screenaudio
  ];
}
