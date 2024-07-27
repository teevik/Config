{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nautilus;
in
{
  options.teevik.apps.nautilus = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nautilus
      '';
    };
  };

  config = mkIf cfg.enable {
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
  };
}
