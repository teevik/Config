{ lib, pkgs, ... }:
let
  hyprland = pkgs.hyprland;
  hyprctl = "${hyprland}/bin/hyprctl";
  light = lib.getExe (pkgs.light);

  checkAudio =
    command: # bash
    ''
      ${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q
      # only suspend if audio isn't running
      if [ $? == 1 ]; then
        ${command}
      fi
    '';
in
{
  services.hypridle = {
    enable = true;

    settings = {
      listeners = [
        {
          timeout = 2 * 60;
          on-timeout = checkAudio "${light} -U 50";
          on-resume = "${light} -A 50";
        }

        {
          timeout = 3 * 60;
          on-timeout = checkAudio "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }

        # {
        #   timeout = 4 * 60;
        #   on-timeout = checkAudio "${hyprctl} dispatch dpms on && ${hyprctl} dispatch exec 'systemctl suspend-then-hibernate'";
        # }
      ];
    };
  };
}
