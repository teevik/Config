{ pkgs, ... }: {
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  # Fixes an issue that normally causes nixos-rebuild to fail.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  users.users.teevik.extraGroups = [ "networkmanager" ];

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
