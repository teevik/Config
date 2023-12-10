{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.lsp-lines;
in
{
  config = mkIf cfg.enable {
    extraConfigLua = /* lua */ ''
      local which_key = require("which-key")

      local is_toggled = false

      local toggle = function()
        is_toggled = not is_toggled

        vim.diagnostic.config({ 
          virtual_lines = is_toggled,
          virtual_text = not is_toggled,
        })
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buffer = args.buf ---@type number
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          vim.diagnostic.config({ 
            virtual_lines = is_toggled,
            virtual_text = not is_toggled,
          })
        end,
      })

      require('which-key').register({
        t = {
          name = "Toggle",
          l = { toggle, "Lsp lines" },
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';
  };
}
