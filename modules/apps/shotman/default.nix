{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    shotman
  ];
}
