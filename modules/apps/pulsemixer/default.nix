{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulsemixer
  ];
}
