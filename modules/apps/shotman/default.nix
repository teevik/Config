{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      shotman
    ];
  };
}