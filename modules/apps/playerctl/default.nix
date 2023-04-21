{ pkgs, ... }:
{
  config.home = {
    services.playerctld.enable = true;
  };
}
