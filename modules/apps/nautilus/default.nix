{ pkgs, ... }:
{
  config = {
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      gnome.nautilus
    ];
  };
}