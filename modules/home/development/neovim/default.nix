{ config
, lib
, inputs
, ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.neovim;
in
{
  options.teevik.development.neovim = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable neovim
      '';
    };
  };

  imports = [ inputs.neovim-flake.homeManagerModules.default ];

  config = mkIf cfg.enable {
    programs.neovim-flake = {
      enable = true;

      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;
          debugMode = {
            enable = false;
            level = 20;
            logFile = "/tmp/nvim.log";
          };
        };

        vim.lsp = {
          formatOnSave = true;
          lspkind.enable = true;
          lightbulb.enable = true;
          lspsaga.enable = false;
          nvimCodeActionMenu.enable = true;
          trouble.enable = true;
          lspSignature.enable = true;
        };

        vim.languages = {
          enableLSP = true;
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          nix.enable = true;
          html.enable = true;
          clang.enable = true;
          sql.enable = true;
          rust = {
            enable = true;
            crates.enable = true;
          };
          ts.enable = true;
          go.enable = true;
          zig.enable = false;
          python.enable = true;
          dart.enable = false;
          elixir.enable = false;
          markdown.enable = true;
        };

        vim.visuals = {
          enable = true;
          nvimWebDevicons.enable = true;
          scrollBar.enable = true;
          smoothScroll.enable = true;
          cellularAutomaton.enable = true;
          fidget-nvim.enable = true;
          cursorline = {
            enable = true;
            lineTimeout = 0;
          };
          indentBlankline = {
            enable = true;
            fillChar = null;
            eolChar = null;
            showCurrContext = true;
          };
        };

        vim.statusline = {
          lualine = {
            enable = true;
            theme = "catppuccin";
          };
        };

        vim.theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = true;
        };
        vim.autopairs.enable = true;

        vim.autocomplete = {
          enable = true;
          type = "nvim-cmp";
        };

        vim.filetree = {
          nvimTree = {
            enable = true;

            view = {
              width = 25;
            };

            git.enable = true;
          };
        };

        vim.tabline = {
          nvimBufferline.enable = true;
        };

        vim.treesitter.context.enable = true;

        vim.binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        vim.telescope.enable = true;

        vim.git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions = false; # throws an annoying debug message
        };

        vim.minimap = {
          minimap-vim.enable = false;
          codewindow.enable = true; # lighter, faster, and uses lua for configuration
        };

        vim.dashboard = {
          dashboard-nvim.enable = false;
          alpha.enable = true;
        };

        vim.notify = {
          nvim-notify.enable = false;
        };

        vim.projects = {
          project-nvim.enable = true;
        };

        vim.utility = {
          ccc.enable = true;
          icon-picker.enable = true;
          diffview-nvim.enable = true;
          motion = {
            hop.enable = true;
            leap.enable = true;
          };
        };

        vim.notes = {
          obsidian.enable = false; # FIXME neovim fails to build if obsidian is enabled
          orgmode.enable = false;
          mind-nvim.enable = true;
          todo-comments.enable = true;
        };

        vim.terminal = {
          toggleterm = {
            enable = true;
            lazygit.enable = true;
          };
        };

        vim.ui = {
          noice.enable = true;
          # smartcolumn.enable = true;
        };

        vim.assistant = {
          copilot.enable = true;
        };

        vim.session = {
          nvim-session-manager.enable = true;
        };

        vim.gestures = {
          gesture-nvim.enable = false;
        };

        vim.comments = {
          comment-nvim.enable = true;
        };
      };
    };
  };
}