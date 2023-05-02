{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    magic-wormhole
  ];
}
