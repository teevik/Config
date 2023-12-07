{ inputs, system, ... }:
let
  nixvim = inputs.nixvim.legacyPackages.${system};
in
nixvim.makeNixvimWithModule
{
  module = {
    imports = [
      ./modules
    ];

    config = {
      options = {
        cursorline = true;
        number = true;
        relativenumber = true;

        timeout = true;
        timeoutlen = 400;
      };

      globals = {
        mapleader = " ";
      };

      colorschemes.catppuccin = {
        enable = true;
        flavour = "mocha";
      };

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

      plugins = {
        # Coding
        treesitter.enable = true;
        twilight.enable = true;
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
