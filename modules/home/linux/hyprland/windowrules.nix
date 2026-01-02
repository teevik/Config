{ lib, osConfig, ... }:
let
  inherit (lib) mkIf;
  enabled = osConfig.programs.hyprland.enable;
  float = [
    "yad"
    "nm-connection-editor"
    "pavucontrolk"
    "xfce-polkit"
    "kvantummanager"
    "qt5ct"
    "VirtualBox Manager"
    "qemu"
    "Qemu-system-x86_64"
    "1Password"

    "org.gnome.Calculator"
    "org.gnome.Nautilus"
    "pavucontrol"
    "nm-connection-editor"
    "blueberry.py"
    "org.gnome.Settings"
    "org.gnome.design.Palette"
    "Color Picker"
    "xdg-desktop-portal"
    "xdg-desktop-portal-gnome"
    "de.haeckerfelix.Fragments"
  ];
in
{
  config = mkIf enabled {
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "match:class ^(${lib.strings.concatStringsSep "|" float})$, float on"
        "match:class ^(libreoffice.*)$, suppress_event maximize"
      ];

      layerrule = [
        "match:namespace bar, blur on"
        "match:namespace osd, blur on"
        "match:namespace notifications, blur on"
        "match:namespace launcher, blur on"
      ];
    };
  };
}
