{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
  ];
}
