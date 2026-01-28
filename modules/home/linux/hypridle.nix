{ pkgs, ... }:
let
  hyprland = pkgs.hyprland;
  hyprctl = "${hyprland}/bin/hyprctl";
  light = "${pkgs.light}/bin/light";
in
{
  services.hypridle = {
    enable = true;

    settings = {
      listener = [
        {
          timeout = 2 * 60;
          on-timeout = "${light} -U 50";
          on-resume = "${light} -A 50";
        }

        {
          timeout = 3 * 60;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }

        # {
        #   timeout = 4 * 60;
        #   on-timeout = "${hyprctl} dispatch dpms on && ${hyprctl} dispatch exec 'systemctl suspend-then-hibernate'";
        # }
      ];
    };
  };
}
