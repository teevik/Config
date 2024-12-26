{ pkgs, ... }: {
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.nautilus
    gnome.nautilus-python
    ffmpegthumbnailer
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment = {
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.gnome.nautilus-python}/lib/nautilus/extensions-4";
    pathsToLink = [
      "/share/nautilus-python/extensions"
    ];
  };
}
