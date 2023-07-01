{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.networking;
in
{
  options.teevik.networking = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable networking
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;

    teevik.user.extraGroups = [ "networkmanager" ];
  };
}
