vim.pack.add({ "https://github.com/stevearc/conform.nvim" }, { confirm = false })
require("conform").setup({
	formatters = {
		typstyle = {
			prepend_args = { "--wrap-text" },
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		rust = { "rustfmt", lsp_format = "fallback" },
		-- JavaScript/TypeScript (oxfmt)
		javascript = { "oxfmt" },
		javascriptreact = { "oxfmt" },
		typescript = { "oxfmt" },
		typescriptreact = { "oxfmt" },
		-- Data formats (oxfmt)
		json = { "oxfmt" },
		jsonc = { "oxfmt" },
		yaml = { "oxfmt" },
		toml = { "oxfmt" },
		-- Web (oxfmt)
		html = { "oxfmt" },
		css = { "oxfmt" },
		scss = { "oxfmt" },
		less = { "oxfmt" },
		vue = { "oxfmt" },
		-- Docs (oxfmt)
		markdown = { "oxfmt" },
		graphql = { "oxfmt" },
		-- Typst
		typst = { "typstyle" },
		-- Nushell
		nu = { "nufmt" },
	},
	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 500,
		lsp_format = "fallback",
	},
})
