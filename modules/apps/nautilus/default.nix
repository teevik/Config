{ pkgs, ... }:
{
  services.gvfs.enable = true;

  services.gnome.sushi.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.nautilus
  ];
}
