{ perSystem, ... }: {
  programs.hyprland = {
    enable = true;
    # package = perSystem.hyprland.default;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
