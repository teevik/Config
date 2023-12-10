{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.nvim-tree;
in
{
  config = mkIf cfg.enable {
    extraConfigLua = /* lua */ ''
      local which_key = require("which-key")

      require('which-key').register({
        g = {
          name = "Goto",
          f = { "<cmd>:NvimTreeFindFile<cr>", "File in Tree" },
        },
        t = {
          name = "Toggle",
          t = { "<cmd>:NvimTreeToggle<cr>", "Nvim tree" },
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';

    plugins.nvim-tree = {
      disableNetrw = true;
      hijackCursor = true;
    };
  };
}
