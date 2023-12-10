{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.nvim-cmp;
in
{
  config = mkIf cfg.enable {
    extraConfigLua = /* lua */ ''
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
    '';

    options = {
      completeopt = "menu,menuone,noinsert";
    };

    plugins = {
      luasnip.enable = true;

      copilot-lua = {
        enable = true;

        suggestion = {
          enabled = false;
          autoTrigger = false;
        };
        panel = {
          enabled = false;
        };

        filetypes = {
          # Disable by default
          "*" = false;
        };
      };

      nvim-cmp = {
        snippet.expand = "luasnip";

        mappingPresets = [ "insert" ];

        experimental = {
          ghost_text = {
            hl_group = "CmpGhostText";
          };
        };

        mapping = {
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })"; # Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

          "<Tab>" = /* lua */ ''
            cmp.mapping(function(fallback)
              local luasnip = require("luasnip")

              if cmp.visible() then
                -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
                cmp.select_next_item()
              -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
              -- this way you will only jump inside the snippet region
              elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end, { "i", "s" })
          '';

          "<S-Tab>" = /* lua */ ''
            cmp.mapping(function(fallback)
              local luasnip = require("luasnip")

              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" })
          '';
        };

        sources = [
          { name = "otter"; }
          {
            name = "copilot";
            groupIndex = 1;
            priority = 4;
          }
          {
            name = "nvim_lsp";
            groupIndex = 1;
            priority = 3;
          }
          {
            name = "luasnip";
            option = {
              show_autosnippets = true;
            };
            groupIndex = 1;
            priority = 5;
          }
          {
            name = "path";
            groupIndex = 1;
          }
          {
            name = "buffer";
            groupIndex = 2;
            priority = 2;
          }
        ];
      };
    };
  };
}
