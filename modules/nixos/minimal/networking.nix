{ perSystem, pkgs, ... }:
{
  networking.networkmanager.enable = true;
  # wifi.backend = "iwd";

  # Fixes an issue that normally causes nixos-rebuild to fail.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  users.users.teevik.extraGroups = [ "networkmanager" ];

  environment.systemPackages = with pkgs; [
    geteduroam-cli
    pkgs.networkmanagerapplet
  ];

  # networking.wireless.iwd = {
  #   enable = true;

  #   settings = {
  #     IPv6 = {
  #       Enabled = true;
  #     };

  #     Settings = {
  #       AutoConnect = true;
  #     };
  #   };
  # };
}
