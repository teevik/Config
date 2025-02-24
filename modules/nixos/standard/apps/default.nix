{ perSystem, config, pkgs, ... }: {
  imports = [
    ./android-studio.nix
    ./nautilus.nix
    ./firefox.nix
  ];

  programs = {
    _1password.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "teevik" ];
    };

    nix-ld.enable = true;

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
    gnome-calendar
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
