{ pkgs, ... }:
{
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    nautilus-python
    ffmpegthumbnailer
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment = {
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    pathsToLink = [
      "/share/nautilus-python/extensions"
    ];
  };
}
