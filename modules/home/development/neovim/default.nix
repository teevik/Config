{ config, lib, inputs, pkgs, ... }:
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

      settings.vim = {
        viAlias = true;
        vimAlias = true;
        debugMode = {
          enable = false;
          level = 20;
          logFile = "/tmp/nvim.log";
        };

        lsp = {
          formatOnSave = true;
          lspkind.enable = true;
          lightbulb.enable = true;
          lspsaga.enable = false;
          nvimCodeActionMenu.enable = true;
          trouble.enable = true;
          lspSignature.enable = true;
        };

        languages = {
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

        visuals = {
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

        statusline = {
          lualine = {
            enable = true;
            theme = "everforest";
          };
        };

        # theme = {
        #   enable = false;
        #   name = "catppuccin";
        #   style = "mocha";
        #   transparent = false;
        # };

        extraPlugins = {
          everforest = {
            package = pkgs.vimPlugins.everforest;
            setup = ''
              vim.cmd.colorscheme "everforest"
            '';
          };
        };

        autopairs.enable = true;

        autocomplete = {
          enable = true;
          type = "nvim-cmp";
        };

        filetree = {
          nvimTree = {
            enable = true;

            view = {
              width = 25;
            };

            git.enable = true;
          };
        };

        tabline = {
          nvimBufferline.enable = true;
        };

        treesitter.context.enable = true;

        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        telescope.enable = true;

        git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions = false; # throws an annoying debug message
        };

        minimap = {
          minimap-vim.enable = false;
          codewindow.enable = true; # lighter, faster, and uses lua for configuration
        };

        dashboard = {
          dashboard-nvim.enable = false;
          alpha.enable = true;
        };

        notify = {
          nvim-notify.enable = false;
        };

        projects = {
          project-nvim.enable = true;
        };

        utility = {
          ccc.enable = true;
          icon-picker.enable = true;
          diffview-nvim.enable = true;
          motion = {
            hop.enable = true;
            leap.enable = true;
          };
        };

        notes = {
          obsidian.enable = false; # FIXME neovim fails to build if obsidian is enabled
          orgmode.enable = false;
          mind-nvim.enable = false;
          todo-comments.enable = true;
        };

        terminal = {
          toggleterm = {
            enable = true;
            lazygit.enable = true;
          };
        };

        ui = {
          noice.enable = true;
          smartcolumn.enable = false;
        };

        assistant = {
          copilot.enable = true;
        };

        session = {
          nvim-session-manager.enable = true;
        };

        comments = {
          comment-nvim.enable = true;
        };
      };
    };
  };
}
