{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.xdg;
  imageViewer = [ "org.gnome.Loupe" ];

  xdgAssociations = type: program: list:
    builtins.listToAttrs (map
      (e: {
        name = "${type}/${e}";
        value = program;
      })
      list);

  image = xdgAssociations "image" imageViewer [ "png" "svg" "jpeg" "gif" ];

in
{
  options.teevik.xdg = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable xdg
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg = {
      enable = true;

      mimeApps = {
        enable = true;
        defaultApplications = image;
      };

      userDirs = {
        enable = true;
        createDirectories = true;

        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
        };
      };
    };
  };
}
