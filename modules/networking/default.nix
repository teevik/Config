{ ... }:
{
  config = {
      networking.hostName = "nixos";
      networking.networkmanager.enable = true;

      # Fixes an issue that normally causes nixos-rebuild to fail.
      # https://github.com/NixOS/nixpkgs/issues/180175
      systemd.services.NetworkManager-wait-online.enable = false;

      pagman.user.extraGroups = [ "networkmanager" ]
  };
}