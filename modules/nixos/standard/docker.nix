{ lib, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = lib.mkDefault false; # Start on-demand via socket activation instead of at boot
  };
  users.users.teevik.extraGroups = [ "docker" ];
}
