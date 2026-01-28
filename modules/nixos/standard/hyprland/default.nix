{
  inputs,
  perSystem,
  pkgs,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.x86_64-linux.hyprland;
  portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;
in
{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = hyprlandPackage;
    portalPackage = portalPackage;
    plugins = [
      perSystem.split-monitor-workspaces.split-monitor-workspaces
    ];
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  environment.systemPackages = [
    perSystem.hyprland-scratchpad.default
  ];

  # Auto-start Hyprland via UWSM from TTY1
  environment.loginShellInit = ''
    if [ "$(tty)" == /dev/tty1 ] && uwsm check may-start; then
      uwsm start default
    fi
  '';
}
