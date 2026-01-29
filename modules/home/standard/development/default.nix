{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  rocPkgs = inputs.roc.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./cargo
    ./neovim
    ./opencode
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    copilot-language-server
    samply
    hyperfine
    fd

    # Devenv
    devenv

    # C++
    clang-tools
    #TODO    lldb

    # Gleam
    gleam
    erlang
    rebar3

    # Glsl
    glsl_analyzer
    #    renderdoc

    # Go
    go
    gopls
    delve

    # Haskell
    # (haskellPackages.ghcWithPackages (pkgs: with pkgs; [
    #   stack
    #   haskell-language-server
    #   doctest
    # ]))

    # JavaScript
    pnpm
    nodejs
    bun
    typescript-go
    emmet-ls
    vtsls
    # nodePackages."@prisma/language-server"
    yarn
    oxlint
    oxfmt

    # Json
    vscode-langservers-extracted

    # Latex
    # texlive.combined.scheme-full
    # texlab
    # python312Packages.pygments

    # Nix
    nil
    nixd
    nixfmt
    # nixpkgs-fmt

    # Odin
    odin
    ols

    # Python
    python3
    pyright
    basedpyright
    uv
    python313Packages.ipykernel
    python313Packages.jupytext
    isort
    black

    # Roc
    # rocPkgs.cli
    # rocPkgs.lang-server

    # Rust
    rustup
    pkg-config
    openssl.dev
    cargo-watch
    lld
    mold
    cargo-wizard

    # Zig
    zig

    # Lua
    lua-language-server
    stylua

    # (jetbrains.idea-ultimate.override {
    #   forceWayland = true;
    # })
  ];

  home.file.".npmrc".text = ''
    prefix=~/.npm-packages
    audit=false
  '';

  home.activation.npm-packages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.npm-packages/lib
  '';

  home.sessionVariables.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
}
