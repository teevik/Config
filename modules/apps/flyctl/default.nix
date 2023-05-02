{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    flyctl
  ];
}
