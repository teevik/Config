{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.lsp;
in
{
  config = mkIf cfg.enable {
    plugins.lsp = {
      onAttach = /* lua */ ''
        do
          local lsp = require("lspconfig")
          local which_key = require("which-key")

          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(bufnr, true)
          end

          -- See `:help vim.lsp.*` for documentation on any of the below functions
          which_key.register({
            g = {
              name = "Go",
              d = { "<cmd>lua vim.lsp.buf.definition()<cr>", "Go to definition" },
              D = { "<cmd>lua vim.lsp.buf.declaration()<cr>", "Go to declaration" },
              h = { "<cmd>lua vim.lsp.buf.hover()<cr>", "Hover" },
              i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Go to implementation" },
              n = { "<cmd>lua require('illuminate').next_reference{wrap=true}<cr>", "Go to next occurrence" },
              p = { "<cmd>lua require('illuminate').next_reference{reverse=true,wrap=true}<cr>", "Go to previous occurrence" },
              r = { "<cmd>lua vim.lsp.buf.references()<cr>", "Go to references" },
              -- t = { "<cmd>lua vim.lsp.buf.type_definition()<cr>", "Go to type definition" },
              ["<C-k>"] = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "Signature help" }
            },
            ["["] = {
              d = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next Diagnostic" },
            },
            ["]"] = {
              d = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous Diagnostic" },
            },
          }, { buffer = buffer, mode = "n", noremap = true, silent = true })

          which_key.register({
            w = {
              name = "Workspace",
              a = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>", "Add workspace" },
              l = { "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<cr>", "List workspaces" },
              r = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>", "Remove workspace" },
            },
            c = {
              name = "Code",
              a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Action" },
              f = { "<cmd>lua vim.lsp.buf.format({ async = true })<cr>", "Format" },
              r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
            },
            t = {
              name = "Toggle",
              i = { function() 
                local bufnr = vim.api.nvim_get_current_buf()
                vim.lsp.inlay_hint.enable(bufnr, not vim.lsp.inlay_hint.is_enabled(bufnr)) 
              end, "Inlay hints" },
            },
          }, { buffer = buffer, mode = "n", prefix = "<leader>", noremap = true, silent = true })
        end
      '';
    };
  };
}
