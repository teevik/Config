{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.standard;
in
{
  options.teevik.suites.standard = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable standard suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      # themes.catppuccin.enable = true;
      themes.everforest.enable = true;

      desktop = {
        fonts.enable = true;
        hyprland.enable = true;
        mako.enable = true;
        swaybg.enable = true;
        waybar.enable = true;

        theming = {
          gtk.enable = true;
          qt.enable = true;
        };
      };

      development = {
        devenv.enable = true;
        direnv.enable = true;
        haskell.enable = false;
        javascript.enable = true;
        neovim.enable = true;

        nix = {
          nil.enable = true;
          nixd.enable = false;
          nixpkgs-fmt.enable = true;
        };

        python.enable = true;
        rust.enable = true;
      };

      hardware = {
        networking.enable = true;
        pipewire.enable = true;
        firmware.enableAllFirmware = true;
        opengl.enable = true;
      };

      services = {
        autologin.enable = true;
        flatpak.enable = true;
        podman.enable = true;
      };

      shells = {
        fish.enable = true;
        nushell.enable = true;
      };

      apps = {
        nh.enable = true;
        alacritty.enable = true;
        wezterm.enable = true;
        chrome.enable = true;
        comma.enable = true;
        darkman.enable = true;
        exa.enable = true;
        feh.enable = true;
        git.enable = true;
        helix.enable = true;
        nautilus.enable = true;
        playerctl.enable = true;
        vscode.enable = true;
        zellij.enable = true;
        tofi.enable = true;
        zathura.enable = true;
        firefox.enable = false;
        neofetch.enable = true;
        webcord.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      bat
      erdtree
      ffmpegthumbnailer
      flyctl
      gcc
      teevik.hyprland-scratchpad
      teevik.insomnia
      just
      magic-wormhole
      mplayer
      networkmanagerapplet
      nurl
      obs-studio
      obsidian
      pavucontrol
      pulsemixer
      # jetbrains.pycharm-professional
      ripgrep
      sd
      shotman
      spotify
      tealdeer
      trashy
      watchexec
      webcord-vencord
      xdg-utils
    ];
  };
}
