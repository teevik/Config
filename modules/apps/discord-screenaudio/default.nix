{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      teevik.discord-screenaudio
    ];
  };
}
