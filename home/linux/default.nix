{ inputs, pkgs, ... }: {
  imports = [
    ./hyprland
    ./waybar
    ./gtk.nix
    ./hypridle.nix
    ./mako.nix
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

  home.packages = with pkgs; [
    inputs.openconnect-sso.packages.${pkgs.system}.openconnect-sso
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    insomnia
    caligula
    mpv
    obs-studio
    trashy
    beekeeper-studio
    xdragon
    loupe
    koji
    super-productivity
    libreoffice-qt6-fresh
    wl-clipboard
    watchman
    zed-editor
    vesktop
  ];
}
