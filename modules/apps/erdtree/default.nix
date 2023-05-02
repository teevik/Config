{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    erdtree
  ];
}
