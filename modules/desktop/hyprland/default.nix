{ config, inputs, ... }:
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  programs.hyprland = {
    enable = true;

    nvidiaPatches = config.teevik.hardware.nvidia.enable;
  };

  teevik.home = {
    imports = [
      inputs.hyprland.homeManagerModules.default
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      systemdIntegration = true;
      recommendedEnvironment = true;

      extraConfig = builtins.readFile ./hyprland.conf;

      nvidiaPatches = config.teevik.hardware.nvidia.enable;
    };
  };
}
