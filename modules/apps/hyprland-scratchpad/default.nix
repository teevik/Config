{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    teevik.hyprland-scratchpad
  ];
}
