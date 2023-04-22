{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      teevik.xwaylandvideobridge
    ];
  };
}
