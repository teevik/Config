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
        hyprland = {
          enable = true;
        };

        mako.enable = true;
        swaybg.enable = true;
        waybar.enable = true;

        theming = {
          gtk.enable = true;
          qt.enable = true;
        };
      };

      apps = {
        nh.enable = true;
        playerctl.enable = true;
        tofi.enable = true;
        chrome.enable = false;
        webcord.enable = true;
        spotify.enable = true;
        anyrun.enable = true;
        firefox.enable = true;
      };

      xdg.enable = true;
    };

    home.packages = with pkgs; [
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      teevik.insomnia
      mplayer
      obs-studio
      trashy
    ];
  };
}
