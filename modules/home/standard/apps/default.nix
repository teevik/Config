{
  inputs,
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  gtk-launch = lib.getExe' pkgs.gtk3 "gtk-launch";
in
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    ./helix
    ./rio
    ./nwg-displays.nix
    ./spotify.nix
  ];

  programs = {
    fzf.enable = true;
    zoxide.enable = true;

    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    kitty = {
      enable = true;

      font.name = "JetBrainsMono Nerd Font";

      themeFile = "Catppuccin-Mocha";

      settings = {
        scrollback_fill_enlarged_window = "yes";
        scrollback_lines = 10000;
        update_check_interval = 0;
        font_size = 13;
        background_opacity = "0.5";
        dynamic_background_opacity = "yes";
        # background_blur = 65;
        window_padding_width = 10;
        allow_remote_control = "yes";
      };

      keybindings = {
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+n" = "new_os_window_with_cwd";
        "ctrl+f" = "launch --type=background --cwd=current ${gtk-launch} org.gnome.Nautilus .";
        "ctrl+e" = "launch --type=background --cwd=current ${gtk-launch} code .";
        "ctrl+backspace" = "send_text all \\x17";
      };
    };

    feh = {
      enable = true;

      buttons = {
        prev_img = null;
        next_img = null;

        zoom_in = 4;
        zoom_out = 5;
      };
    };

    git = {
      enable = true;
      delta.enable = true;

      userEmail = "teemu.vikoren@gmail.com";
      userName = "teevik";
      ignores = [
        ".DS_Store"
      ];

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        rerere.enabled = true;
        # pull.rebase = true;
      };
    };

    tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };

    btop = {
      enable = true;

      settings = {
        color_theme = "TTY";
        theme_background = false;
      };
    };

    fuzzel = {
      enable = true;

      settings = {
        main = {
          font = "Source Sans:size=16";
          line-height = 22;
          terminal = "kitty";
        };

        border = {
          width = 2;
          radius = 8;
        };

        dmenu = {
          mode = "text";
        };

        colors = {
          background = "1e1e2edd";
          text = "cdd6f4ff";
          prompt = "bac2deff";
          placeholder = "7f849cff";
          input = "cdd6f4ff";
          match = "cba6f7ff";
          selection = "585b70ff";
          selection-text = "cdd6f4ff";
          selection-match = "cba6f7ff";
          counter = "7f849cff";
          border = "cba6f7ff";
        };
      };
    };
  };

  home.packages = with pkgs; [
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
    xournalpp
    azure-cli
    terraform
    terraform-ls
    graphviz
    ngrok
    git-agecrypt
    neofetch
    sysz
    claude-code
  ];
}
