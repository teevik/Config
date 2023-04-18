{ inputs, ... }:
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = {
    programs.hyprland.enable = true;

    home = {
      imports = [
        inputs.hyprland.homeManagerModules.default
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;

        extraConfig = builtins.readFile ./hyprland.conf;
      };
    };
  };
}