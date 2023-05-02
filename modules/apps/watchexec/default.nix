{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    watchexec
  ];
}
