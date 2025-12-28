{ config, ... }:
{
  services.cachix-watch-store = {
    enable = false;
    cacheName = "teevik";
    cachixTokenFile = config.age.secrets.cachix.path;
  };
}
