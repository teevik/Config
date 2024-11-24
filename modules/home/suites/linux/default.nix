{ inputs, pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.linux;
in
{
  options.teevik.suites.linux = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable linux suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      desktop = {
        hyprland.enable = true;
        i3.enable = true;

        mako.enable = true;
        swaybg.enable = true;
        waybar.enable = true;

        theming = {
          gtk.enable = true;
          qt.enable = true;
        };
      };

      development = {
        glsl.enable = true;
      };

      apps = {
        nh.enable = true;
        playerctl.enable = true;
        tofi.enable = true;
        chrome.enable = false;
        webcord.enable = true;
        spotify.enable = true;
        firefox.enable = true;
        distrobox.enable = true;
        nwg-displays.enable = true;
      };

      xdg.enable = true;
    };

    home.packages = with pkgs; [
      inputs.openconnect-sso.packages.${pkgs.system}.openconnect-sso
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      teevik.insomnia
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
    ];
  };
}
