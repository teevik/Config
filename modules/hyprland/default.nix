{ inputs, ... }:
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = {
    programs.hyprland.enable = true;

    pagman.home.extraOptions = {
      imports = [
        inputs.hyprland.homeManagerModules.default
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;

        extraConfig = import ./config.nix;
      };
    };
  };
}