{ pkgs, ... }:
{
  config.home = {
    services.playerctld.enable = true;
  };

  config = {
    environment.systemPackages = with pkgs; [
      playerctl
    ];
  };
}
