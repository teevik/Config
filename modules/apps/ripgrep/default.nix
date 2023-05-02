{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ripgrep
    ripgrep-all
  ];
}
