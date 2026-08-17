{
  lib,
  perSystem,
  pkgs,
  ...
}:
{
  imports = [
    ../../shared/packages
  ];

  programs.ydotool = {
    enable = true;
    group = "input";
  };

  users.users.teevik.extraGroups = [ "input" ];

  system.userActivationScripts.clearTofiDrunCache.text = ''
    cacheHome="''${XDG_CACHE_HOME:-$HOME/.cache}"
    rm -f "$cacheHome/tofi-drun"
  '';

  environment.systemPackages =
    (with pkgs; [
      # Dev tools - C++
      clang-tools

      # Dev tools - Gleam
      erlang
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
      typescript-go
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

      solidtime-desktop
      ticktick
    ])
    ++ [
      perSystem.openconnect-sso.default
      pkgs.zoom-us
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      pkgs.stremio-linux-shell
    ];

  # Nix-index database for command-not-found
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
