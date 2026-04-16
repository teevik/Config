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

  # playwright-cli with browser revision symlinks
  # playwright-cli bundles playwright-core 1.59 (expects revision 1212/2259)
  # but nixpkgs playwright-browsers are built for 1.58 (revision 1208/2248)
  playwright-browsers-compat = pkgs.runCommand "playwright-browsers-compat" { } ''
    mkdir -p $out
    ln -s ${pkgs.playwright-driver.browsers}/chromium-* $out/chromium-1212
    ln -s ${pkgs.playwright-driver.browsers}/chromium_headless_shell-* $out/chromium_headless_shell-1212
    ln -s ${pkgs.playwright-driver.browsers}/firefox-* $out/firefox-1509
    ln -s ${pkgs.playwright-driver.browsers}/webkit-* $out/webkit-2259
    ln -s ${pkgs.playwright-driver.browsers}/ffmpeg-* $out/ffmpeg-1011
  '';

  playwright-cli-wrapped = pkgs.symlinkJoin {
    name = "playwright-cli-wrapped";
    paths = [ pkgs.playwright-cli ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/playwright-cli \
        --set PLAYWRIGHT_BROWSERS_PATH "${playwright-browsers-compat}" \
        --set PLAYWRIGHT_MCP_BROWSER "chromium"
    '';
  };

  # Stremio from pinned nixpkgs
  pinnedNixpkgs =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/5135c59491985879812717f4c9fea69604e7f26f.tar.gz";
        sha256 = "09qy7zv80bkd9ighsw0bdxjq70dw3qjnyvg7il1fycrsgs5x1gan";
      })
      {
        system = pkgs.stdenv.hostPlatform.system;
      };

  # ols-dev-2026-02 is incompatible with odin-dev-2026-04 (core:os/os2 was renamed)
  ols-patched = pkgs.ols.overrideAttrs (_: {
    version = "dev-2026-03";
    src = pkgs.fetchFromGitHub {
      owner = "DanielGavin";
      repo = "ols";
      tag = "dev-2026-03";
      hash = "sha256-QjkzR9Wnc+Poq7dxDlik9k1maEs8xiFuNbwRdv8nqyo=";
    };
  });
in
{
  environment.systemPackages = with pkgs; [
    # CLI Utilities
    bat
    erdtree
    moreutils
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
    fastfetch
    sysz
    hyperfine
    trashy
    caligula
    lynx
    chromium

    # Shells
    nushell
    fish
    carapace

    # Editors
    perSystem.helix.default
    perSystem.neovim.default
    unzip # needed by neovim
    vscode
    zed-editor

    # Terminal Emulators
    kitty
    rio

    # File Management
    yazi
    feh
    dragon-drop

    # Git
    git
    delta
    worktrunk

    # Dev Tools - General
    gcc
    direnv
    nix-direnv
    copilot-language-server
    samply
    devenv
    claude-code
    dioxus-cli
    playwright-cli-wrapped

    # Dev Tools - C++
    clang-tools

    # Dev Tools - Gleam
    gleam
    erlang
    rebar3

    # Dev Tools - GLSL
    glsl_analyzer

    # Dev Tools - Go
    go
    gopls
    delve

    # Dev Tools - JavaScript
    pnpm
    nodejs
    bun
    typescript-go
    emmet-ls
    vtsls
    yarn
    oxlint
    oxfmt

    # Dev Tools - JSON
    vscode-langservers-extracted

    # Dev Tools - Odin
    odin
    ols-patched

    # Dev Tools - Nix
    nil
    nixd
    nixfmt

    # Dev Tools - Python
    python3
    pyright
    basedpyright
    uv
    python313Packages.ipykernel
    python313Packages.jupytext
    isort
    black

    # Dev Tools - Rust
    rustup
    pkg-config
    openssl.dev
    cargo-watch
    lld
    mold
    cargo-wizard

    # Dev Tools - Zig
    zig
    zls

    # Dev Tools - Lua
    lua-language-server
    stylua

    # Desktop Apps
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

    # Hyprland Tools
    inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
    perSystem.self.peck
    wl-clipboard
    watchman
    swaybg
    tofi-patched
    fuzzel

    # OpenCode
    perSystem.self.opencode
    perSystem.self.opencode-desktop

    # Theming
    catppuccin-cursors.mochaDark
    (catppuccin-gtk.override {
      accents = [ "pink" ];
      size = "standard";
      tweaks = [ "rimless" ];
      variant = "mocha";
    })
    adwaita-qt

    pinnedNixpkgs.stremio
    perSystem.marble.default
    perSystem.openconnect-sso.default
    nix-index
    comma
    perSystem.self.duat
  ];

  # Nix-index database for command-not-found
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
