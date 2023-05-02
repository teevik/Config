{ ... }:
{
  services.getty.autologinUser = "teevik";

  environment.loginShellInit = ''
    if [ "$(tty)" == /dev/tty1 ]; then
      Hyprland
    fi
  '';
}
