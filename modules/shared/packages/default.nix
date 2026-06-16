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

  # playwright-cli bundles playwright-core 1.59 (expects revision 1212/2259)
  # but nixpkgs playwright-browsers are built for 1.58 (revision 1208/2248).
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

  # ols-dev-2026-04 is incompatible with odin-dev-2026-04 (filepath API changes).
  ols-patched = pkgs.ols.overrideAttrs (_: {
    version = "dev-2026-05";
    src = pkgs.fetchFromGitHub {
      owner = "DanielGavin";
      repo = "ols";
      tag = "dev-2026-05";
      hash = "sha256-9tQVyauvXGTkKnQUSYKAhjL5ZZbhglqdcxdcs27P2k4=";
    };
  });
in
{
  environment.systemPackages =
    (with pkgs; [
      # CLI utilities
      bat
      btop
      caligula
      erdtree
      fastfetch
      fd
      fzf
      gh
      gtk3
      hyperfine
      just
      libnotify
      lynx
      magic-wormhole
      moreutils
      nurl
      ripgrep
      sd
      sysz
      tealdeer
      trashy
      typos
      watchexec
      wavemon
      xdg-utils
      zoxide

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
      dragon-drop
      feh
      kitty
      rio
      xdg-terminal-exec
      yazi

      # Git
      delta
      git
      worktrunk

      # Dev tools - general
      claude-code
      copilot-language-server
      devenv
      direnv
      dioxus-cli
      gcc
      nix-direnv
      pkg-config
      samply

      # Dev tools - C++
      clang-tools

      # Dev tools - Gleam
      erlang
      gleam
      rebar3

      # Dev tools - GLSL
      glsl_analyzer

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
      typescript-go
      vtsls
      yarn

      # Dev tools - JSON
      vscode-langservers-extracted

      # Dev tools - Odin
      odin
      ols-patched

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

      # Dev tools - Zig
      zig
      zls

      # Dev tools - Lua
      lua-language-server
      stylua

      # Dev tools - Typst
      typst
      typstyle

      # Nix and repo tools
      comma
      git-agecrypt
      nix-index
      nix-inspect
      perSystem.self.duat

      # Work tools
      perSystem.self.opencode

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
      perSystem.antigravity.default
      perSystem.marble.default
      pkgs.opencode-desktop
      playwright-cli-wrapped
      rounded
      solidtime-desktop
      ticktick
      vesktop
      xournalpp
      zotero

      # Wayland tools
      inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
      fuzzel
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
      xwayland-satellite
    ])
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.spotify
    ];
}
