{ pkgs, osConfig, ... }:
let
  hyprland = osConfig.programs.hyprland.finalPackage;
  hyprctl = "${hyprland}/bin/hyprctl";
in
{
  home.stateVersion = "23.11";

  services.swayidle = {
    enable = true;

    systemdTarget = "hyprland-session.target";

    timeouts = [
      {
        timeout = 2 * 60;
        command = "${hyprctl} dispatch dpms off";
        resumeCommand = "${hyprctl} dispatch dpms on";
      }

      {
        timeout = 4 * 60;
        command = "${hyprctl} dispatch exec 'systemctl suspend-then-hibernate'";
      }
    ];
  };

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };
  };

  home.packages = with pkgs; [
    jetbrains.clion
  ];
}
