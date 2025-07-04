{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  rocPkgs = inputs.roc.packages.${pkgs.system};
in
{
  imports = [ ./cargo ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
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
    nodejs
    bun
    typescript
    biome
    emmet-ls
    vtsls
    # nodePackages."@prisma/language-server"
    yarn

    # Json
    vscode-langservers-extracted

    # Latex
    texlive.combined.scheme-full
    texlab
    python312Packages.pygments

    # Nix
    nil
    nixd
    nixfmt-rfc-style
    # nixpkgs-fmt

    # Odin
    odin
    ols

    # Python
    python3
    pyright
    uv

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
