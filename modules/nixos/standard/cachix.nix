{ config, ... }:
{
  services.cachix-watch-store = {
    enable = true;
    cacheName = "teevik";
    cachixTokenFile = config.sops.secrets.cachix.path;
  };
}
