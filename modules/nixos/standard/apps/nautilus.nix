{ pkgs, ... }:
let
  # This customization is only needed by the installed file manager, not by
  # every package depending on Nautilus in the nixpkgs fixed point.
  nautilus = pkgs.nautilus.overrideAttrs (old: {
    buildInputs =
      old.buildInputs
      ++ (with pkgs.gst_all_1; [
        gst-plugins-good
        gst-plugins-bad
      ]);
  });
in
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
}
