{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.distrobox;
in
{
  options.teevik.apps.distrobox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable distrobox
      '';
    };
  };


  config = mkIf cfg.enable {
    home.packages = [
      pkgs.distrobox
    ];

    xdg.configFile = {
      "distrobox/distrobox.conf".text = ''
        container_always_pull="1"
        container_manager="docker"
      '';

      "distrobox/distrobox.ini" = {
        text = pkgs.lib.generators.toINI { } {
          arch = {
            home = "/tmp/arch-home";
            image = "ghcr.io/teevik/arch:main";
            pull = true;
            root = false;
            replace = true;
          };
        };

        onChange = ''
          export PATH=${pkgs.docker}/bin:$PATH
          ${lib.getExe' pkgs.distrobox "distrobox"} assemble create --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini
        '';
      };
    };
  };
}

