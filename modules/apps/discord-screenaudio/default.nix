{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [
      pkgs.teevik.discord-screenaudio
    ];
  };
}
