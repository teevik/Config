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
      themes.catppuccin.enable = true;
      # themes.everforest.enable = true;

      development = {
        devenv.enable = true;
        direnv.enable = true;
        haskell.enable = false;
        javascript.enable = true;
        cpp.enable = true;
        zig.enable = true;

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
        alacritty.enable = false;
        wezterm.enable = true;
        kitty.enable = true;
        comma.enable = true;
        exa.enable = true;
        feh.enable = true;
        git.enable = true;
        helix.enable = true;
        vscode.enable = true;
        zellij.enable = true;
        zathura.enable = true;
        firefox.enable = true;
        neofetch.enable = true;
        anyrun.enable = true;
        neovim.enable = true;
      };
    };

    home.packages = with pkgs; [
      teevik.asciiquarium
      teevik.asciiquarium-fullscreen
      bat
      erdtree
      flyctl
      gcc
      just
      magic-wormhole
      nurl
      (obsidian.override { electron = electron_24; })
      ripgrep
      sd
      tealdeer
      watchexec
      xdg-utils
      yazi
    ];
  };
}
