{
  inputs,
  flake,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-system-graphics.systemModules.default
    # flake.modules.shared.packages
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;

  fonts.fontconfig.enable = true;

  environment = {
    etc."nix/nix.custom.conf".text = ''
      experimental-features = nix-command flakes ca-derivations dynamic-derivations parallel-eval
      auto-optimise-store = true
      trusted-users = root teemu.vikoeren
      max-substitution-jobs = 128
      http-connections = 128
      eval-cores = 0
      lazy-trees = true
      keep-derivations = true
      keep-outputs = true
      connect-timeout = 5
      fallback = true
      substituters = https://cache.nixos.org https://teevik.cachix.org https://hyprland.cachix.org https://install.determinate.systems
      trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= desktop-1:VvIgYHAClUfjQjKWeNaCiQTRm9Q3fO0Q3v08KLTp0yo= teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
    '';

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_STYLE_OVERRIDE = "adwaita-dark";
    };

    pathsToLink = [
      "/bin"
      "/share/applications"
      "/share/fonts"
      "/share/glib-2.0/schemas"
      "/share/hyprland"
      "/share/icons"
      "/share/mime"
      "/share/nautilus-python/extensions"
      "/share/pixmaps"
      "/share/thumbnailers"
    ];

    systemPackages = with pkgs; [
      iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.ubuntu
      nerd-fonts.fira-code
      source-sans
    ];
  };
}
