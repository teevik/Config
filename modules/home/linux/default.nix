{
  inputs,
  pkgs,
  perSystem,
  ...
}:
{
  imports = [
    ./hyprland
    ./mango
    ./zed
    ./firefox.nix
    ./gtk.nix
    ./hypridle.nix
    ./kanshi.nix
    ./marble.nix
    ./niri.nix
    ./qt.nix
    ./swaybg.nix
    ./tofi.nix
  ];

  programs = {
    vscode.enable = true;

    yazi = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };
  };

  services = {
    cliphist.enable = true;
  };

  xdg.desktopEntries."org.gnome.Settings" = {
    name = "Settings";
    comment = "Gnome Control Center";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
    categories = [ "X-Preferences" ];
    terminal = false;
  };

  home.packages = with pkgs; [
    inputs.openconnect-sso.packages.${pkgs.system}.openconnect-sso
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast

    libnotify
    caligula
    mpv
    obs-studio
    trashy
    # beekeeper-studio
    dragon-drop
    loupe
    koji
    # super-productivity
    solidtime-desktop
    libreoffice-qt6-fresh
    wl-clipboard
    watchman
    vesktop
    wavemon
    perSystem.antigravity.default
    kiro-fhs
  ];
}
