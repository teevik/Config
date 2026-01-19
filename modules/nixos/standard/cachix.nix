{ config, ... }:
{
  services.cachix-watch-store = {
    enable = true;
    cacheName = "teevik";
    cachixTokenFile = config.age.secrets.cachix.path;
  };
}
