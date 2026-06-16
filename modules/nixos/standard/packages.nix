{
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  pinnedNixpkgs =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/5135c59491985879812717f4c9fea69604e7f26f.tar.gz";
        sha256 = "09qy7zv80bkd9ighsw0bdxjq70dw3qjnyvg7il1fycrsgs5x1gan";
      })
      {
        system = pkgs.stdenv.hostPlatform.system;
      };
in
{
  imports = [
    ../../shared/packages
  ];

  programs.ydotool = {
    enable = true;
    group = "input";
  };

  users.users.teevik.extraGroups = [ "input" ];

  environment.systemPackages =
    (with pkgs; [
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

      # Dev tools - Zig
      zig
      zls

      # Dev tools - Lua
      lua-language-server
      stylua

      # Dev tools - Typst
      typst
      typstyle

      solidtime-desktop
      ticktick
    ])
    ++ [
      perSystem.openconnect-sso.default
      pkgs.zoom-us
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pinnedNixpkgs.stremio
    ];

  # Nix-index database for command-not-found
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
