{ writeScriptBin
, lib
, inputs
, pkgs
,
}:
let
  configModule = {
    config.vim = {
      # Debug
      debugMode = {
        enable = false;
        level = 20;
        logFile = "/tmp/nvim.log";
      };

      # # Everforest theme
      # extraPlugins = {
      #   everforest = {
      #     package = pkgs.vimPlugins.everforest;
      #     setup = ''
      #       vim.cmd.colorscheme "everforest"
      #     '';
      #   };
      # };

      useSystemClipboard = true;

      # Catppuccin
      theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
        transparent = false;
      };

      # Statusline
      statusline.lualine = {
        enable = true;
        theme = "catppuccin";
      };

      # Toggleterm as a replacement to built-in terminal command
      terminal.toggleterm = {
        # <C-t> to toggle
        enable = true;
        # <leader>gg to open
        lazygit.enable = true;
      };

      lsp = {
        # Enable format on save
        formatOnSave = true;

        # Icons in lsp completion
        lspkind.enable = true;

        # Lightbulb icons when code action is available
        lightbulb.enable = true;

        # Show nvim diagnostics using virtual lines
        lsplines.enable = true;

        # Display lsp hover documentation in a side panel
        nvim-docs-view.enable = true;

        #  Pop-up menu for code actions
        nvimCodeActionMenu.enable = true;

        # A pretty list for showing diagnostics
        trouble.enable = true;

        # LSP signature hint as you type
        lspSignature.enable = true;
      };

      # Autocomplete
      autocomplete = {
        enable = true;
        type = "nvim-cmp";
      };

      # Multi-purpose search and picker
      telescope.enable = true;

      binds = {
        # Keybind helper menu
        whichKey.enable = true;

        # Cheatsheet, `:Cheatsheet` to use
        cheatsheet.enable = true;
      };

      # Visuals
      visuals = {
        enable = true;

        # Devicons
        nvimWebDevicons.enable = true;

        # Scrollbar, [nvim-scrollbar]
        scrollBar.enable = true;

        # Smooth scrolling, [cinnamon-nvim]
        smoothScroll.enable = true;

        # Extensible UI for Neovim notifications and LSP progress messages.
        fidget-nvim.enable = true;

        # Highlighting on cursor
        cursorline.enable = true;

        # Indentation lines
        indentBlankline = {
          enable = true;
          fillChar = null;
          eolChar = null;
          showCurrContext = true;
        };
      };

      ui = {
        # Visible borders for most windows
        borders.enable = true;

        # noice-nvim UI
        noice.enable = true;

        # Color highlighting for css [nvim-colorizer]
        colorizer.enable = true;
      };

      assistant = {
        copilot = {
          enable = true;

          # Copilot suggestions will automatically be loaded into your cmp menu as snippets
          cmp.enable = true;
        };
      };

      # Comment plugin [comment-nivm]
      # `gc` to toggle comment
      comments.comment-nvim.enable = true;

      # Filetree
      filetree.nvimTree = {
        enable = true;

        view = {
          width = {
            min = 20;
            max = 35;
          };
        };

        git.enable = true;

        # Hijack directory buffers
        hijackDirectories = {
          enable = true;
          autoOpen = true;
        };

        openOnSetup = false;
      };

      # Bufferline at top of screen
      tabline.nvimBufferline.enable = true;

      # Show context of current function/class at top of screen [nvim-treesitter-context]
      treesitter.context.enable = true;

      # Git tools via gitsigns
      git = {
        enable = true;
        gitsigns.enable = true;
      };

      # Dashboard
      dashboard.alpha.enable = true;

      # Notifications
      notify.nvim-notify.enable = true;

      utility = {
        # `w g z` to surround word
        surround.enable = true;
      };

      # Languages
      languages = {
        enableLSP = true;
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        html.enable = true;
        clang = {
          enable = true;
          lsp.server = "clangd";
        };
        sql.enable = false;
        rust = {
          enable = true;
          crates.enable = true;
        };
        java.enable = true;
        ts.enable = true;
        svelte.enable = true;
        go.enable = true;
        zig.enable = true;
        python.enable = true;
        dart.enable = false;
        elixir.enable = false;
        bash.enable = true;
      };
    };
  };

  neovimPackage =
    (inputs.neovim-flake.lib.neovimConfiguration {
      modules = [
        configModule
      ];
      pkgs = pkgs;
    }).neovim;

  neovim = lib.getExe neovimPackage;
  kitty = lib.getExe pkgs.kitty;
in
writeScriptBin "nvim" ''
  #!/usr/bin/env bash
  ${kitty} @ set-spacing padding=0
  ${kitty} @ set-background-opacity 1

  ${neovim} $1 $2 $3

  ${kitty} @ set-spacing padding=10
  ${kitty} @ set-background-opacity 0
''
