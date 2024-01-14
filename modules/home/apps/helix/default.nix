{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.helix;
  inherit (config.teevik.theme) helixTheme;
in
{
  options.teevik.apps.helix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable helix
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "helix/themes/catppuccin_mocha.toml".source = ./themes/catppuccin_mocha.toml;
    };

    programs.helix = {
      enable = true;

      package =
        let
          helix = lib.getExe pkgs.helix;
          # helix = lib.getExe (inputs.helix.packages.${pkgs.system}.default);
          kitty = lib.getExe pkgs.kitty;
        in
        pkgs.writeScriptBin "hx" ''
          #!/usr/bin/env bash
          ${kitty} @ set-spacing padding=0
          ${kitty} @ set-background-opacity 1

          ${helix} $1 $2 $3

          ${kitty} @ set-spacing padding=10
          ${kitty} @ set-background-opacity 0
        '';

      settings = {
        theme = helixTheme;

        editor = {
          line-number = "relative";
          bufferline = "always";
          color-modes = true;
          # auto-save = true;
          cursorline = true;

          scrolloff = 10;
          completion-trigger-len = 1;
          idle-timeout = 100;
        };

        editor.lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        editor.cursor-shape = {
          insert = "bar";
        };

        editor.indent-guides = {
          render = true;
        };

        keys.normal = {
          esc = [ "collapse_selection" "keep_primary_selection" ];
          "C-/" = "toggle_comments";

          # ctrl-d from vscode
          # "C-d" = ["move_prev_word_start", move_next_word_end", "search_selection", "extend_search_next"]
          # make sure there is only one selection, select word under cursor, set search to selection, then switch to select mode
          "C-d" = [ "keep_primary_selection" "move_prev_word_start" "move_next_word_end" "search_selection" "select_mode" ];
        };

        keys.select = {
          # if already in select mode, just add new selection at next occurrence
          "C-d" = [ "search_selection" "extend_search_next" ];
        };

        keys.insert = {
          "C-s" = ":w";
        };
      };
    };

    xdg.configFile."helix/languages.toml".text = ''
      [language-server.nil]
      config.formatting.command = [ "nixpkgs-fmt" ]

      [[language]]
      name = "nix"
      auto-format = true
    '';
  };
}


