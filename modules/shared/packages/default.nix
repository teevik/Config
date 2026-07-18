{
  inputs,
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  xdg-terminal-exec = pkgs.writeShellScriptBin "xdg-terminal-exec" ''
    exec ${pkgs.kitty}/bin/kitty "$@"
  '';

  rounded = pkgs.writeShellScriptBin "roundify" ''
    ${pkgs.imagemagick}/bin/magick -   \( +clone  -alpha extract     -draw 'fill black polygon 0,0 0,15 15,0 fill white circle 15,15 15,0'     \( +clone -flip \) -compose Multiply -composite     \( +clone -flop \) -compose Multiply -composite   \) -alpha off -compose CopyOpacity -composite -
  '';

  tofi-patched = pkgs.tofi.overrideAttrs (_: {
    patches = [ ./tofi.patch ];
  });
in
{
  environment.systemPackages =
    (with pkgs; [
      # CLI utilities
      bubblewrap
      btop
      fd
      fzf
      gh
      gtk3
      hyperfine
      just
      libnotify
      magic-wormhole
      moreutils
      nurl
      ripgrep
      sd
      tealdeer
      trashy
      watchexec
      xdg-utils
      stow

      # Shells
      carapace
      fish
      nu_scripts
      nushell
      nushellPlugins.skim

      # Editors
      perSystem.helix.default
      perSystem.neovim.default
      perSystem.zed.default
      unzip # needed by neovim
      vscode

      # Terminal and file management
      feh
      kitty
      xdg-terminal-exec
      yazi

      # Git
      delta
      git

      # Dev tools - general
      devenv
      direnv
      gcc
      nix-direnv
      pkg-config

      # Dev tools - Nix
      nil
      nixd
      nixfmt

      # Dev tools - Python
      black
      isort
      ty
      uv

      # Dev tools - Rust
      cargo-pgo
      cargo-watch
      cargo-wizard
      lld
      llvmPackages.bolt
      mold
      openssl.dev
      rustup

      # Nix and repo tools
      comma
      nix-index
      nix-inspect

      # Work tools
      # perSystem.self.opencode

      # Desktop apps
      chromium
      graphviz
      koji
      libreoffice-qt6-fresh
      loupe
      mpv
      ngrok
      obs-studio
      obsidian
      perSystem.marble.default
      # pkgs.opencode-desktop
      rounded
      vesktop
      xournalpp
      zotero
      pavucontrol

      # Wayland tools
      perSystem.hyprland-contrib.grimblast
      fuzzel
      nwg-displays
      perSystem.self.peck
      swaybg
      tofi-patched
      watchman
      wl-clipboard

      # Theming
      adwaita-qt
      catppuccin-cursors.mochaDark
      (catppuccin-gtk.override {
        accents = [ "pink" ];
        size = "standard";
        tweaks = [ "rimless" ];
        variant = "mocha";
      })

      # GNOME apps
      adwaita-icon-theme
      baobab
      evince
      ffmpegthumbnailer
      gnome-boxes
      gnome-calculator
      gnome-clocks
      gnome-control-center
      gnome-system-monitor
      gnome-text-editor
      gnome-weather
      libheif
      libheif.out
      morewaita-icon-theme
      papirus-icon-theme
      rtk
      wakatime-cli
    ])
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.spotify
    ];
}
