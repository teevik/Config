{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    sd
  ];
}
