{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      teevik.hyprland-scratchpad
    ];
  };
}
