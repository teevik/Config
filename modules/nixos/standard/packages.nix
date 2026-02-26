{
  inputs,
  perSystem,
  pkgs,
  ...
}:
let
  # Custom scripts
  rounded = pkgs.writeShellScriptBin "roundify" ''
    magick -   \( +clone  -alpha extract     -draw 'fill black polygon 0,0 0,15 15,0 fill white circle 15,15 15,0'     \( +clone -flip \) -compose Multiply -composite     \( +clone -flop \) -compose Multiply -composite   \) -alpha off -compose CopyOpacity -composite -
  '';

  xdg-terminal-exec = pkgs.writeShellScriptBin "xdg-terminal-exec" ''
    kitty "$@"
  '';

  # Patched tofi
  tofi-patched = pkgs.tofi.overrideAttrs (oldAttrs: {
    patches = [ ./patches/tofi.patch ];
  });

  # OpenCode v1.2.15 override
  opencode-latest = pkgs.opencode.overrideAttrs (old: rec {
    version = "1.2.15";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-26MV9TbyAF0KFqZtIHPYu6wqJwf0pNPdW/D3gDQEUlQ=";
    };
    node_modules = old.node_modules.overrideAttrs {
      inherit src;
      outputHash = "sha256-Diu/C8b5eKUn7MRTFBcN5qgJZTp0szg0ECkgEaQZ87Y=";
    };
  });

  opencode-desktop-latest =
    (pkgs.opencode-desktop.override {
      opencode = opencode-latest;
    }).overrideAttrs
      (old: {
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (opencode-latest) src;
          sourceRoot = "${opencode-latest.src.name}/packages/desktop/src-tauri";
          hash = "sha256-WI48iYdxmizF1YgOQtk05dvrBEMqFjHP9s3+zBFAat0=";
        };
      });

  # Stremio from pinned nixpkgs
  pinnedNixpkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/5135c59491985879812717f4c9fea69604e7f26f.tar.gz";
        sha256 = "09qy7zv80bkd9ighsw0bdxjq70dw3qjnyvg7il1fycrsgs5x1gan";
      })
      {
        system = pkgs.stdenv.hostPlatform.system;
      };
in
{
  environment.systemPackages = with pkgs; [
    # --- CLI Utilities ---
    tmux
    bat
    erdtree
    ripgrep
    sd
    fd
    fzf
    zoxide
    just
    gh
    watchexec
    magic-wormhole
    nurl
    xdg-utils
    xdg-terminal-exec
    gtk3
    tealdeer
    neofetch
    sysz
    hyperfine
    trashy
    caligula

    # --- Shells ---
    nushell
    fish
    carapace

    # --- Editors ---
    perSystem.helix.default
    perSystem.neovim.default
    unzip # needed by neovim
    vscode
    zed-editor

    # --- Terminal Emulators ---
    kitty
    rio

    # --- File Management ---
    yazi
    feh
    dragon-drop

    # --- Git ---
    git
    delta

    # --- Dev Tools - General ---
    gcc
    direnv
    nix-direnv
    copilot-language-server
    samply
    devenv
    claude-code
    dioxus-cli

    # --- Dev Tools - C++ ---
    clang-tools

    # --- Dev Tools - Gleam ---
    gleam
    erlang
    rebar3

    # --- Dev Tools - GLSL ---
    glsl_analyzer

    # --- Dev Tools - Go ---
    go
    gopls
    delve

    # --- Dev Tools - JavaScript ---
    pnpm
    nodejs
    bun
    typescript-go
    emmet-ls
    vtsls
    yarn
    oxlint
    oxfmt

    # --- Dev Tools - JSON ---
    vscode-langservers-extracted

    # --- Dev Tools - Nix ---
    nil
    nixd
    nixfmt

    # --- Dev Tools - Python ---
    python3
    pyright
    basedpyright
    uv
    python313Packages.ipykernel
    python313Packages.jupytext
    isort
    black

    # --- Dev Tools - Rust ---
    rustup
    pkg-config
    openssl.dev
    cargo-watch
    lld
    mold
    cargo-wizard

    # --- Dev Tools - Zig ---
    zig
    zls

    # --- Dev Tools - Lua ---
    lua-language-server
    stylua

    # --- Desktop Apps ---
    obsidian
    ticktick
    xournalpp
    graphviz
    ngrok
    nix-inspect
    git-agecrypt
    rounded
    mpv
    obs-studio
    loupe
    koji
    solidtime-desktop
    libreoffice-qt6-fresh
    vesktop
    wavemon
    perSystem.antigravity.default
    btop
    spotify
    libnotify
    zotero
    zoom-us

    # --- Hyprland Tools ---
    inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
    wl-clipboard
    watchman
    swaybg
    light
    tofi-patched
    fuzzel

    # --- OpenCode ---
    opencode-latest
    opencode-desktop-latest

    # --- Theming ---
    catppuccin-cursors.mochaDark
    (catppuccin-gtk.override {
      accents = [ "pink" ];
      size = "standard";
      tweaks = [ "rimless" ];
      variant = "mocha";
    })
    adwaita-qt

    # --- Stremio (pinned) ---
    pinnedNixpkgs.stremio

    # --- Marble Shell ---
    perSystem.marble.default

    # --- VPN ---
    inputs.openconnect-sso.packages.${pkgs.stdenv.hostPlatform.system}.openconnect-sso

    # --- nix-index + comma ---
    nix-index
    comma
  ];

  # Nix-index database for command-not-found
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
