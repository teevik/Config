{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.nvim-tree;
in
{
  config = mkIf cfg.enable {
    keymaps = [
      {
        mode = "n";
        key = "<C-n>";
        action = "<cmd>:NvimTreeToggle<cr>";
        options = {
          silent = true;
          desc = "Toggle Tree";
        };
      }
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>:NvimTreeFindFile<cr>";
        options = {
          silent = true;
          desc = "CurrentFile";
        };
      }
    ];

    extraConfigLua = ''
      local which_key = require("which-key")

      require('which-key').register({
        g = {
          name = "Goto",
          f = { "<cmd>:NvimTreeFindFile<cr>", "File in Tree" },
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';

    plugins.nvim-tree = {
      disableNetrw = true;
      hijackCursor = true;
    };
  };
}
