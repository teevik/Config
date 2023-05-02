{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nurl
  ];
}
