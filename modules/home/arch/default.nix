{ config, lib, pkgs, ... }:
{
  targets.genericLinux.enable = true;

  programs.kitty.package = pkgs.emptyDirectory;
  wayland.windowManager.hyprland.package = lib.mkForce null;

  xdg.configFile."paru/paru.conf".source = ./paru.conf;

  programs.nh = {
     enable = true;
     clean.enable = true;
     clean.extraArgs = "--keep-since 4d --keep 3";
     flake = "${config.home.homeDirectory}/Documents/Config";
   };
}
