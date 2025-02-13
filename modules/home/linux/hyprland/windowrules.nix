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
  ];
in
{
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "float, class:^(${lib.strings.concatStringsSep "|" float})$"
      "suppressevent maximize, class:^(libreoffice.*)$"
    ];
  };
}
