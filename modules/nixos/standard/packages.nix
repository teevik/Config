{
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  nuPluginSkimOverlay = _final: prev: {
    nushellPlugins = prev.nushellPlugins // {
      skim = prev.nushellPlugins.skim.overrideAttrs (oldAttrs: rec {
        version = "0.30.0";

        src = prev.fetchFromGitHub {
          owner = "idanarye";
          repo = "nu_plugin_skim";
          tag = "v${version}";
          hash = "sha256-bZiNUQon4x82XQKINrDYTn6IgEZmLwhhFvmYMTBLOmA=";
        };

        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-s0VU8S/V/HJJ5DPLIFvUqhxu9391PJYY/tROUbfJnDQ=";
        };

        nativeInstallCheckInputs = (oldAttrs.nativeInstallCheckInputs or [ ]) ++ [ prev.nushell ];
        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck

          plugin_registry="$PWD/skim-plugins.msgpackz"
          nu --plugin-config "$plugin_registry" \
            -c "plugin add $out/bin/nu_plugin_skim"

          runHook postInstallCheck
        '';
      });
    };
  };
in
{
  imports = [
    ../../shared/packages
  ];

  nixpkgs.overlays = [ nuPluginSkimOverlay ];

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
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;
}
