{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      xwaylandvideobridge
    ];
  };
}
