{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.telescope;
in
{
  config = mkIf cfg.enable {
    extraConfigLua = /* lua */ ''
      local which_key = require("which-key")
      local telescope = require("telescope")
      local api = require("telescope.builtin")

      require('which-key').register({
        f = {
          name = "Find",
          f = { "<cmd>Telescope find_files<cr>", "Find File" },
          F = {
            function()
              api.find_files { hidden = true }
            end,
            "Find File (Hidden)"
          },
          r = { "<cmd>Telescope oldfiles<cr>", "Recent File" },
          g = { "<cmd>Telescope live_grep<cr>", "Grep" },
          G = {
            function()
              api.live_grep { hidden = true }
            end,
            "Grep (Hidden Files)"
          },
          b = { "<cmd>Telescope buffers<cr>", "Find Buffer" },
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';
  };
}
