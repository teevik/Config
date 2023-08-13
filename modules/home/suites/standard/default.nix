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

      shells = {
        fish.enable = true;
        nushell.enable = true;
      };

      apps = {
        home-manager.enable = true;
        nh.enable = true;
        alacritty.enable = true;
        wezterm.enable = true;
        chrome.enable = true;
        comma.enable = true;
        exa.enable = true;
        feh.enable = true;
        git.enable = true;
        helix.enable = true;
        vscode.enable = true;
        zellij.enable = true;
        tofi.enable = true;
        zathura.enable = true;
        firefox.enable = false;
        neofetch.enable = true;
        webcord.enable = true;
      };
    };

    home.packages = with pkgs; [
      bat
      erdtree
      flyctl
      gcc
      teevik.insomnia
      just
      magic-wormhole
      mplayer
      nurl
      obs-studio
      obsidian
      ripgrep
      sd
      spotify
      tealdeer
      trashy
      watchexec
      xdg-utils
    ];
  };
}
