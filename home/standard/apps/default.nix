{ inputs, pkgs, lib, ... }:
let gtk-launch = lib.getExe' pkgs.gtk3 "gtk-launch";
in {
  imports = [ inputs.nix-index-database.hmModules.nix-index ];

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
  ];
}
