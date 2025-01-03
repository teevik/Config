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
      themes.catppuccin.enable = lib.mkDefault true;
      themes.everforest.enable = lib.mkDefault false;
      themes.tokyo-night.enable = lib.mkDefault false;

      development = {
        devenv.enable = true;
        direnv.enable = true;
        haskell.enable = true;
        javascript.enable = true;
        cpp.enable = true;
        zig.enable = true;
        go.enable = true;
        odin.enable = false;
        json.enable = true;

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
        wezterm.enable = false;
        kitty.enable = true;
        comma.enable = true;
        exa.enable = true;
        # feh.enable = true;
        git.enable = true;
        helix.enable = true;
        vscode.enable = true;
        zellij.enable = true;
        zathura.enable = false;
        neofetch.enable = true;
        neovim.enable = true;
        yazi.enable = true;
        tealdeer.enable = true;
        atuin.enable = true;
        carapace.enable = true;
      };
    };

    programs.fzf.enable = true;
    programs.zoxide.enable = true;

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
      obsidian
      ripgrep
      sd
      watchexec
      xdg-utils
      yazi
      wrk
      bruno
      gh
      gitu
      nix-inspect
      fh
      xournalpp
      azure-cli
      terraform
      terraform-ls
      graphviz
      ngrok
      git-agecrypt
    ];
  };
}
