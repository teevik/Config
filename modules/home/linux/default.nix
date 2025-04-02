{ inputs, pkgs, ... }:
{
  imports = [
    ./hyprland
    ./firefox.nix
    ./gtk.nix
    ./hypridle.nix
    ./marble.nix
    ./qt.nix
    ./swaybg.nix
    ./tofi.nix
    ./zed.nix
  ];

  programs = {
    vscode.enable = true;

    yazi = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };
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
    insomnia
    caligula
    mpv
    obs-studio
    trashy
    # beekeeper-studio
    xdragon
    loupe
    koji
    super-productivity
    libreoffice-qt6-fresh
    wl-clipboard
    watchman
    vesktop
    wavemon
  ];
}
