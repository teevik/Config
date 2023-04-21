{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      gnome.nautilus
    ];
  };
}
