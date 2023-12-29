{ pkgs, inputs, system, ... }:
let
  nixvim = inputs.nixvim.legacyPackages.${system};
in
nixvim.makeNixvimWithModule
{
  inherit pkgs;

  extraSpecialArgs = {
    osInputs = inputs;
  };

  module = {
    imports = [
      ./modules
    ];

    config = {
      # Neovim nightly
      package = pkgs.neovim-unwrapped.overrideAttrs (old: {
        version = "0.10.0-dev";
        src = pkgs.fetchFromGitHub {
          owner = "neovim";
          repo = "neovim";
          rev = "29aa4dd10af74d29891cb293dc9ff393e9dba11f";
          hash = "sha256-WcGPELMcBCuxNwyO5ULBV5do52O05TWJHBTS4M4Vnlo=";
        };
      });

      colorschemes.catppuccin = {
        enable = true;
        flavour = "mocha";
      };

      options = {
        cursorline = true;
        number = true;
        relativenumber = true;

        timeout = true;
        timeoutlen = 300;

        signcolumn = "yes";
        expandtab = true;
        shiftwidth = 2;

        undofile = true;
      };

      globals = {
        mapleader = " ";
      };

      keymaps = [
        {
          mode = "v";
          key = "<";
          action = "<gv";
          options = {
            silent = true;
          };
        }
        {
          mode = "v";
          key = ">";
          action = ">gv";
          options = {
            silent = true;
          };
        }
        {
          mode = "n";
          key = "U";
          action = ":redo<CR>";
          options = {
            silent = true;
          };
        }
        {
          mode = "n";
          key = "W";
          action = "b";
          options = {
            silent = true;
          };
        }
      ];

      languages = {
        nix.enable = true;
        rust.enable = true;
        bash.enable = true;
        cpp.enable = true;
        go.enable = true;
        web.enable = true;
        lua.enable = true;
        python.enable = true;
      };

      extraPlugins = with pkgs.vimPlugins; [
        dressing-nvim
      ];

      plugins = {
        # Coding
        treesitter.enable = true;
        twilight.enable = false;
        vim-visual-multi.enable = true;
        todo-comments.enable = true;
        telescope.enable = true;
        surround = {
          # ys<motion>

          enable = true;
        };

        # LSP
        lsp.enable = true;
        lsp-format.enable = true; # Format on save
        lsp-lines.enable = true;
        nvim-cmp.enable = true;
        lspkind.enable = true;
        otter.enable = true;

        # UI
        which-key.enable = true;
        notify.enable = true;
        noice.enable = true;
        nvim-colorizer.enable = true;
        lualine.enable = true;
        indent-blankline.enable = true;
        alpha.enable = true;
        bufferline.enable = true;

        nvim-tree = {
          # <C-n> to toggle
          # e to rename
          # a to create file
          # d to delete

          enable = true;
        };

        # Mini
        mini = {
          enable = true;

          animate = true;
          comment = true;
          pairs = true;
          indentscope = true;
        };
      };
    };
  };
}
