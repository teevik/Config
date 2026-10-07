{
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

  t3code-desktop-nightly = perSystem.llm-agents.t3code-desktop.override {
    t3code = perSystem.self.t3code-nightly;
  };

  agentPython = pkgs.python3.withPackages (
    ps: with ps; [
      # HTTP and parsing
      beautifulsoup4
      httpx
      lxml
      requests

      # Data, images, and documents
      matplotlib
      numpy
      openpyxl
      pandas
      pillow
      pypdf
      python-docx
      pyyaml
      scipy

      # General scripting and testing
      pydantic
      pytest
      rich
    ]
  );
in
{
  programs = {
    ydotool = {
      enable = true;
      group = "input";
    };

    # Nix-index database for command-not-found
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    command-not-found.enable = false;
  };

  users.users.teevik.extraGroups = [
    "input"
    # Serial access to ZMK keyboards (/dev/ttyACM*) for ZMK Studio
    "dialout"
  ];

  system.userActivationScripts.clearTofiDrunCache.text = ''
    cacheHome="''${XDG_CACHE_HOME:-$HOME/.cache}"
    rm -f "$cacheHome/tofi-drun"
  '';

  environment.systemPackages =
    (with pkgs; [
      # CLI utilities
      bubblewrap
      btop
      expect
      fd
      fastfetch
      fzf
      gh
      glab
      gtk3
      hyperfine
      immich-cli
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
      intelli-shell
      nu_scripts
      nushell
      nushellPlugins.skim
      zoxide

      # Editors
      code-cursor
      helix
      neovim
      zed-editor
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
      git-subrepo

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
      agentPython

      # Dev tools - Rust
      cargo-pgo
      cargo-watch
      cargo-wizard
      lld
      llvmPackages.bolt
      mold
      openssl.dev
      rustup

      # Dev tools - Roc
      perSystem.self.roc-nightly

      # Nix and repo tools
      nix-inspect
      perSystem.self.nix-update

      # Work tools
      agent-browser
      perSystem.self.fox
      perSystem.self.agent-workspace-linux
      perSystem.llm-agents.chatgpt
      perSystem.llm-agents.claude-code
      perSystem.llm-agents.claude-desktop
      perSystem.llm-agents.codex
      perSystem.self.t3code-nightly
      t3code-desktop-nightly
      perSystem.self.opencode

      # Desktop apps
      graphviz
      koji
      libreoffice-qt-stable
      loupe
      mpv
      ngrok
      obs-studio
      obsidian
      perSystem.self.opencode-desktop
      rounded
      vesktop
      xournalpp
      perSystem.self.zotero
      pavucontrol

      # Wayland tools
      perSystem.hyprland-contrib.grimblast
      cliphist
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
      perSystem.self.figma-linux
      pkgs.spotify
    ]
    ++ (with pkgs; [
      # Dev tools - C++
      ccache
      clang-tools

      # Dev tools - Gleam
      beamPackages.erlang
      gleam
      rebar3

      # Dev tools - shaders
      glsl_analyzer
      shader-slang

      # Dev tools - Go
      delve
      go
      gopls

      # Dev tools - JavaScript
      bun
      emmet-ls
      nodejs
      oxfmt
      oxlint
      pnpm
      typescript
      vtsls
      yarn

      # Dev tools - JSON
      vscode-langservers-extracted

      # Dev tools - Odin
      odin
      ols

      # Dev tools - Zig
      zig
      zls

      # Dev tools - Lua
      lua-language-server
      stylua

      # Dev tools - Typst
      typst
      typstyle
      harper

      solidtime-desktop
      ticktick
      zmk-studio
    ])
    ++ [
      perSystem.self.openconnect-sso
      pkgs.zoom-us
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.stremio-linux-shell
    ];

}
