{ pkgs, ... }:
{
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    nautilus-python
    ffmpegthumbnailer
    pkgs.libheif
    pkgs.libheif.out
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment = {
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    pathsToLink = [
      "/share/nautilus-python/extensions"
      "share/thumbnailers"
    ];
  };

  # gstreamer
  nixpkgs.overlays = [
    (final: prev: {
      nautilus = prev.nautilus.overrideAttrs (nprev: {
        buildInputs =
          nprev.buildInputs
          ++ (with pkgs.gst_all_1; [
            gst-plugins-good
            gst-plugins-bad
          ]);
      });
    })
  ];
}
