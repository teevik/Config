{ config, lib, inputs, system, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.archetypes.workstation;
in
{
  options.teevik.archetypes.workstation = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable workstation archetype
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      hyprland = {
        enable = true;
      };

      development = {
        devenv.enable = true;
        direnv.enable = true;
        haskell.enable = false;
        javascript.enable = true;
        neovim.enable = false;

        nix = {
          nil.enable = true;
          nixd.enable = true;
          nixpkgs-fmt.enable = true;
        };

        python.enable = true;
        rust.enable = true;
      };

      fonts.enable = true;

      hardware = {
        firmware.enableAllFirmware = true;
        opengl.enable = true;
      };

      networking.enable = true;
      nix-ld.enable = false;
      pipewire.enable = true;

      services = {
        autologin.enable = true;
        flatpak.enable = true;
        podman.enable = true;
      };

      shells = {
        fish.enable = true;
        nushell.enable = true;
      };

      theming = {
        gtk.enable = true;
        qt.enable = true;
      };

      apps = {
        alacritty.enable = true;
        bat.enable = true;
        chrome.enable = true;
        clion.enable = true;
        comma.enable = true;
        darkman.enable = true;
        erdtree.enable = true;
        exa.enable = true;
        feh.enable = true;
        ffmpegthumbnailer.enable = true;
        flyctl.enable = true;
        gcc.enable = true;
        git.enable = true;
        helix.enable = true;
        hyprland-scratchpad.enable = true;
        just.enable = true;
        lutris.enable = lib.mkDefault false;
        magic-wormhole.enable = true;
        mplayer.enable = true;
        nautilus.enable = true;
        networkmanager-applet.enable = true;
        nh.enable = true;
        nurl.enable = true;
        obs-studio.enable = true;
        obsidian.enable = true;
        pavucontrol.enable = true;
        playerctl.enable = true;
        pulsemixer.enable = true;
        pycharm.enable = false;
        ripgrep.enable = true;
        sd.enable = true;
        shotman.enable = true;
        spotify.enable = true;
        steam.enable = lib.mkDefault false;
        tealdear.enable = true;
        tofi.enable = true;
        trashy.enable = true;
        vscode.enable = true;
        watchexec.enable = true;
        webcord.enable = true;
        xdg-utils.enable = true;
        zellij.enable = true;
      };
    };
  };
}
