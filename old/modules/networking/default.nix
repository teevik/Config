{ options, config, pkgs, lib, ... }:
{
  config =  {
    pagman.user.extraGroups = [ "networkmanager" ];

    networking.networkmanager.enable = true;

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
