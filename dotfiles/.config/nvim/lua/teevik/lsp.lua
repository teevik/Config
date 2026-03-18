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
			vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr, desc = "[R]ename symbol" })
		end,
	},

	excluded_servers = {
		"ccls", -- prefer clangd
		"denols", -- prefer vtsls
		"docker_compose_language_service", -- yamlls should be enough?
		"flow", -- prefer vtsls
		"ltex", -- grammar tool using too much CPU
		"quick_lint_js", -- prefer oxlint and vtsls
		"scry", -- archived on Jun 1, 2023
		"tailwindcss", -- associates with too many filetypes
		"biome", -- using oxlint instead
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

-- Odin Language Server (not managed by lazy-lsp, requires ols binary on PATH)
vim.lsp.config("ols", {
	cmd = { "ols" },
	filetypes = { "odin" },
	root_markers = { "ols.json", ".git" },
	on_attach = function(client, bufnr)
		vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
		vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = bufnr, desc = "[R]ename symbol" })
	end,
})
vim.lsp.enable("ols")

vim.lsp.on_type_formatting.enable()

vim.pack.add({ "https://github.com/folke/lazydev.nvim" }, { confirm = false })
require("lazydev").setup()
