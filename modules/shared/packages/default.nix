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
  environment.systemPackages =
    (with pkgs; [
      # CLI utilities
      bubblewrap
      btop
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
      perSystem.self.nu-plugin-skim
      zoxide

      # Editors
      perSystem.self.helix
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

      # Nix and repo tools
      nix-inspect
      perSystem.self.nix-update

      # Work tools
      agent-browser
      perSystem.self.agent-workspace-linux
      pi-coding-agent
      perSystem.llm-agents.claude-code
      perSystem.llm-agents.claude-desktop
      perSystem.llm-agents.codex
      perSystem.llm-agents.omp
      perSystem.self.t3code-nightly
      t3code-desktop-nightly
      perSystem.self.opencode

      # Desktop apps
      chromium
      graphviz
      koji
      libreoffice-qt-stable
      loupe
      mpv
      ngrok
      obs-studio
      obsidian
      perSystem.marble.default
      perSystem.self.opencode-desktop
      rounded
      vesktop
      xournalpp
      zotero
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
    ];
}
