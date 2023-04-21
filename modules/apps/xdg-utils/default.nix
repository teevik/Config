{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      xdg-utils
    ];
  };
}
