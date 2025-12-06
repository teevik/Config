-- Space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable true color support
vim.opt.termguicolors = true

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- enable break indent
vim.opt.breakindent = true

-- save undo history
vim.opt.undofile = true

-- case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- decrease update time
vim.opt.updatetime = 250

-- decrease mapped sequence wait time
-- displays which-key popup sooner
vim.opt.timeoutlen = 300

-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- show which line your cursor is on
vim.opt.cursorline = true

-- set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

-- enable line wrapping
vim.opt.wrap = true

-- formatting
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.textwidth = 80

-- session options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
	virtual_text = true, -- show inline diagnostics
})

-- clear search highlights with <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- yank to system clipboard
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "[Y]ank to clipboard" })

-- redo with Ctrl+u
vim.keymap.set("n", "<C-u>", "<C-r>", { desc = "Redo" })

-- Catppuccin colorscheme
vim.pack.add({ "https://github.com/catppuccin/nvim" }, { confirm = false })
vim.cmd.colorscheme("catppuccin-mocha")

require("teevik.treesitter")
require("teevik.nvim-cmp")
require("teevik.lsp")
require("teevik.conform")
require("teevik.snacks")
-- require("teevik.magenta")

-- Lualine
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" }, { confirm = false })

require("lualine").setup({
	options = {
		section_separators = { left = "", right = "" },
		component_separators = { left = "", right = "" },
	},
})

-- WhichKey
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })

require("which-key").setup({
	spec = {
		{ "<leader>b", group = "[B]uffer" },
		{ "<leader>c", group = "[C]ode" },
		{ "<leader>f", group = "[F]ind" },
		{ "<leader>g", group = "[G]oto" },
		{ "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } },
		{ "<leader>u", group = "[U]I" },
		{ "<leader>w", group = "[W]orkspace" },
	},
})

-- Utility plugins
vim.pack.add({
	"https://github.com/windwp/nvim-autopairs", -- auto pairs
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO/INFO/WARN comments
	"https://github.com/rmagatti/auto-session", -- automatic sessions
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/noamsto/resolved.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/akinsho/bufferline.nvim",
}, { confirm = false })

require("nvim-autopairs").setup()
require("todo-comments").setup()
require("auto-session").setup({
	autoload = true,
	suppressed_dirs = { "~/", "~/Documents/Projects", "~/Downloads", "/" },
	pre_restore_cmds = {
		function()
			local pickers = Snacks.picker.get({ source = "explorer" })

			if pickers and pickers[1] then
				pickers[1]:close()
			end
		end,
	},
})
vim.keymap.set("n", "<leader>wr", "<cmd>AutoSession search<CR>", { desc = "Session search" })
vim.keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session" })
vim.keymap.set("n", "<leader>wa", "<cmd>AutoSession toggle<CR>", { desc = "Toggle autosave" })
require("resolved").setup({})

require("bufferline").setup({
	options = {
		diagnostics = "nvim_lsp",
		middle_mouse_command = "bdelete %d",
	},
})

-- Buffer navigation
vim.keymap.set("n", "gn", "<cmd>bnext<CR>", { desc = "Go to next buffer" })
vim.keymap.set("n", "gp", "<cmd>bprevious<CR>", { desc = "Go to previous buffer" })
vim.keymap.set("n", "<leader>bc", "<cmd>bdelete<CR>", { desc = "[C]lose buffer" })

-- Toggle comment
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })

-- copilot-language-server
-- vim.lsp.config("copilot", {
-- 	cmd = { "copilot-language-server", "--stdio" },
-- 	handlers = {
-- 		didChangeStatus = function(err, res, _)
-- 			if err then
-- 				return
-- 			end
-- 			if res.status == "Error" then
-- 				vim.notify("Please use `:LspCopilotSignIn` to sign into Copilot", vim.log.levels.ERROR)
-- 			end
-- 		end,
-- 	},
-- })

-- vim.lsp.config("copilot", {})
-- vim.lsp.enable("copilot")
--
-- vim.pack.add({ "https://github.com/folke/sidekick.nvim" }, { confirm = false })
-- require("sidekick").setup({})
--
-- -- if there is a next edit, jump to it, otherwise apply it if any
-- vim.keymap.set({ "n", "i" }, "<C-l>", function()
-- 	require("sidekick").nes_jump_or_apply()
-- end, { desc = "Goto/Apply Next Edit Suggestion" })

vim.pack.add({ "https://github.com/supermaven-inc/supermaven-nvim" }, { confirm = false })
require("supermaven-nvim").setup({
	-- condition = function()
	-- 	return false
	-- end,
})

-- vim.pack.add(
-- 	{ "https://github.com/copilotlsp-nvim/copilot-lsp", "https://github.com/zbirenbaum/copilot.lua" },
-- 	{ confirm = false }
-- )
--
-- require("copilot-lsp").setup({})
--
-- vim.g.copilot_nes_debounce = 500
-- vim.lsp.enable("copilot_ls")
-- vim.keymap.set({ "n", "i" }, "<tab>", function()
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	local state = vim.b[bufnr].nes_state
-- 	if state then
-- 		-- Try to jump to the start of the suggestion edit.
-- 		-- If already at the start, then apply the pending suggestion and jump to the end of the edit.
-- 		local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
-- 			or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
-- 		return nil
-- 	else
-- 		-- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
-- 		return "<C-i>"
-- 	end
-- end, { desc = "Accept Copilot NES suggestion", expr = true })

vim.pack.add({ "https://github.com/alexpasmantier/krust.nvim" }, { confirm = false })

require("krust").setup({
	keymap = "<leader>k",
})

vim.pack.add({ "https://github.com/NickvanDyke/opencode.nvim" }, { confirm = false })

vim.keymap.set({ "n", "x" }, "<C-a>", function()
	require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask opencode" })
vim.keymap.set({ "n", "x" }, "<C-x>", function()
	require("opencode").select()
end, { desc = "Execute opencode action…" })
vim.keymap.set({ "n", "x" }, "ga", function()
	require("opencode").prompt("@this")
end, { desc = "Add to opencode" })
vim.keymap.set({ "n", "t" }, "<C-.>", function()
	require("opencode").toggle()
end, { desc = "Toggle opencode" })
vim.keymap.set("n", "<S-C-u>", function()
	require("opencode").command("session.half.page.up")
end, { desc = "opencode half page up" })
vim.keymap.set("n", "<S-C-d>", function()
	require("opencode").command("session.half.page.down")
end, { desc = "opencode half page down" })
-- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o".
vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })
