{ lib, ... }:
let
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
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "float, class:^(${lib.strings.concatStringsSep "|" float})$"
      "suppressevent maximize, class:^(libreoffice.*)$"
    ];

    layerrule = [
      "blur, bar"
      "blur, osd"
      "blur, notifications"
      "blur, launcher"
    ];
  };
}
