vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig", -- default configs for lsps
	"https://github.com/dundalek/lazy-lsp.nvim",
}, { confirm = false })

require("lazy-lsp").setup({
	use_vim_lsp_config = true,

	default_config = {
		on_attach = function(client, bufnr)
			-- enable inlay hints if supported
			-- if client.server_capabilities.inlayHintProvider then
			-- 	vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			-- end

			-- keybinds
			vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
		end,
	},

	excluded_servers = {
		"ccls", -- prefer clangd
		"denols", -- prefer eslint and ts_ls
		"docker_compose_language_service", -- yamlls should be enough?
		"flow", -- prefer eslint and ts_ls
		"ltex", -- grammar tool using too much CPU
		"quick_lint_js", -- prefer eslint and ts_ls
		"scry", -- archived on Jun 1, 2023
		"tailwindcss", -- associates with too many filetypes
		"biome", -- not mature enough to be default
		"oxlint", -- prefer eslint
	},
	preferred_servers = {
		markdown = {},
		python = { "basedpyright", "ruff" },
	},

	configs = {
		lua_ls = {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		},
	},
})

vim.lsp.on_type_formatting.enable()

vim.pack.add({ "https://github.com/folke/lazydev.nvim" }, { confirm = false })
require("lazydev").setup()
