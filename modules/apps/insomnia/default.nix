{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    insomnia
  ];
}
