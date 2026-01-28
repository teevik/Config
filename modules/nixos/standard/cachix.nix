{ config, ... }:
{
  services.cachix-watch-store = {
    enable = false;
    cacheName = "teevik";
    cachixTokenFile = config.sops.secrets.cachix.path;
  };
}
