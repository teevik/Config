{
  perSystem,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./android-studio.nix
    ./nautilus.nix
    ./firefox.nix
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs = {
    hyprland = {
      enable = true;
      package = perSystem.hyprland.default;
    };

    _1password = {
      enable = true;
      package = perSystem.unstable._1password-cli;
    };

    _1password-gui = {
      enable = true;
      package = perSystem.unstable._1password-gui;
      polkitPolicyOwners = [ "teevik" ];
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        hyprland
        stdenv.cc.cc.lib
        zlib
        # glib.dev
        # pango.dev
        # gtk3
        # cairo.dev
      ];
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "${config.users.users.teevik.home}/Documents/Config";
    };
  };

  environment.systemPackages = with pkgs; [
    git

    morewaita-icon-theme
    adwaita-icon-theme
    papirus-icon-theme
    gnome-control-center
    gnome-text-editor
    # gnome-calendar
    gnome-boxes
    gnome-system-monitor
    gnome-control-center
    gnome-weather
    gnome-calculator
    gnome-clocks
    baobab

    # config.boot.kernelPackages.perf
    # perSystem.self.vk_hdr_layer
  ];

  services.fwupd.enable = true;
}
