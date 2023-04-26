{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [
      pkgs.libsForQt5.callPackage ./package { }
      # pkgs.teevik.discord-screenaudio
    ];
  };
}
