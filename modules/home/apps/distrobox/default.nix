{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.distrobox;
  listToPackages = list: "\"${lib.strings.concatStrings (lib.strings.intersperse " " list)}\"";
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
        container_manager="podman"
      '';

      "distrobox/distrobox.ini" = {
        text = pkgs.lib.generators.toINI { } {
          arch = {
            image = "ghcr.io/greyltc-org/archlinux-aur:paru";
            additional_packages = listToPackages [ "eza" "bat" ];
            pull = true;
            root = false;
            replace = true;
          };
        };

        # onChange = ''
        #   export PATH=${pkgs.podman}/bin:$PATH
        #   ${lib.getExe pkgs.distrobox} assemble create --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini
        # '';
      };
    };
  };
}

