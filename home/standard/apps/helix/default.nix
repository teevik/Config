{ pkgs, config, lib, inputs, ... }:
let
  inherit (config.teevik.theme) helixTheme;
in
{
  xdg.configFile = {
    "helix/themes/catppuccin_mocha.toml".source = ./catppuccin_mocha.toml;
  };


  programs.helix = {
    enable = true;

    package =
      let
        helix = inputs.helix.packages.${pkgs.system}.default;
        helixBin = lib.getExe helix;
        kittyBin = lib.getExe pkgs.kitty;

        helix-kitty-integration = pkgs.writeScriptBin "hx" ''
          #!/usr/bin/env bash

          if [ $KITTY_WINDOW_ID ]; then
            ${kittyBin} @ set-spacing padding=0
            ${kittyBin} @ set-background-opacity 1
          fi

          ${helixBin} $1 $2 $3

          if [ $KITTY_WINDOW_ID ]; then
            ${kittyBin} @ set-spacing padding=10
            ${kittyBin} @ set-background-opacity ${builtins.toJSON config.teevik.theme.kittyOpacity}
          fi
        '';
      in
      pkgs.runCommand
        "${helix.name}-kitty-integration"
        { }
        ''
          mkdir -p $out/{share,bin}
          ${pkgs.xorg.lndir}/bin/lndir -silent ${helix}/share $out/share
          cp ${helix-kitty-integration}/bin/hx $out/bin
        ''
    ;

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

        lsp = {
          display-messages = true;
          display-inlay-hints = false;
        };

        inline-diagnostics = {
          cursor-line = "hint";
          other-lines = "disable";
        };

        cursor-shape = {
          insert = "bar";
        };

        indent-guides = {
          render = true;
        };
      };

      keys.normal = {
        "W" = "move_prev_word_start";

        esc = [ "collapse_selection" "keep_primary_selection" ];
        "C-/" = "toggle_comments";

        # ctrl-d from vscode
        # "C-d" = ["move_prev_word_start", move_next_word_end", "search_selection", "extend_search_next"]
        # make sure there is only one selection, select word under cursor, set search to selection, then switch to select mode
        "C-d" = [ "keep_primary_selection" "move_prev_word_start" "move_next_word_end" "search_selection" "select_mode" ];

        space."i" = ":toggle lsp.display-inlay-hints";
        space."e" = ":toggle inline-diagnostics.other-lines error disable";
      };

      keys.select = {
        "W" = "move_prev_word_start";
        # if already in select mode, just add new selection at next occurrence
        "C-d" = [ "search_selection" "extend_search_next" ];
      };

      keys.insert = {
        "S-tab" = "unindent";
        "C-s" = ":w";
        "C-w" = "copilot_apply_completion";
      };
    };
  };
}
