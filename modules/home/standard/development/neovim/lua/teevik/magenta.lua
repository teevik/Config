vim.pack.add({ "https://github.com/dlants/magenta.nvim" }, { confirm = false })

-- TODO: Hack until https://github.com/dlants/magenta.nvim/issues/169 is fixed
require("magenta.keymaps").default_keymaps = function() end

require("magenta").setup({
	profiles = {
		{
			name = "claude-opus",
			provider = "anthropic",
			model = "claude-opus-4-5",
			fastModel = "claude-haiku-4-5", -- optional, defaults provided
			authType = "max", -- Use Anthropic OAuth instead of API key
			thinking = {
				enabled = false,
				budgetTokens = 1024, -- optional, defaults to 1024, must be >= 1024
			},
		},
	},

	-- open chat sidebar on left or right side
	sidebarPosition = "right",
	-- can be changed to "telescope" or "snacks"
	picker = "snacks",
	-- enable default keymaps shown below
	defaultKeymaps = false,
	-- maximum number of sub-agents that can run concurrently (default: 3)
	maxConcurrentSubagents = 3,
	-- volume for notification chimes (range: 0.0 to 1.0, default: 0.3)
	-- set to 0.0 to disable chimes entirely
	chimeVolume = 0.3,
	-- glob patterns for files that should be auto-approved for getFile tool
	-- (bypasses user approval for hidden/gitignored files matching these patterns)
	-- getFileAutoAllowGlobs = { "node_modules/*" }, -- default includes node_modules,
	-- directories containing skill subdirectories (default: { ".claude/skills" })
	-- skillsPaths = { ".claude/skills", "custom/skills" },
	-- keymaps for the sidebar input buffer
	-- sidebarKeymaps = {
	-- 	normal = {
	-- 		["<CR>"] = ":Magenta send<CR>",
	-- 	},
	-- },
	-- keymaps for the inline edit input buffer
	-- if keymap is set to function, it accepts a target_bufnr param
	inlineKeymaps = {
		normal = {
			["<CR>"] = function(target_bufnr)
				vim.cmd("Magenta submit-inline-edit " .. target_bufnr)
			end,
		},
	},
	-- configure edit prediction options
	editPrediction = {
		-- Use a dedicated profile for predictions (optional)
		-- If not specified, uses the current active profile's model
		profile = {
			provider = "anthropic",
			model = "claude-sonnet-4-5",
			authType = "max",
		},
		-- Maximum number of changes to track for context (default: 10)
		changeTrackerMaxChanges = 20,
		-- Token budget for including recent changes (default: 1000)
		recentChangeTokenBudget = 1500,
		-- Customize the system prompt (optional)
		-- systemPrompt = "Your custom prediction system prompt here...",
		-- Add instructions to the default system prompt (optional)
		systemPromptAppend = "Focus on completing function calls and variable declarations.",
	},

	-- configure MCP servers for external tool integrations
	mcpServers = {
		-- fetch = {
		--     command = "uvx",
		--     args = { "mcp-server-fetch" }
		-- },
		-- playwright = {
		--     command = "npx",
		--     args = {
		--         "@playwright/mcp@latest"
		--     }
		-- },
		-- -- HTTP-based MCP server example
		-- httpServer = {
		--     url = "http://localhost:8000/mcp",
		--     requestInit = {
		--         headers = {
		--             Authorization = "Bearer your-token-here",
		--         },
		--     },
		-- }
	},
})

vim.keymap.set(
	"i",
	"<C-l>",
	"<Cmd>Magenta predict-edit<CR>",
	{ silent = true, noremap = true, desc = "Predict/accept edit" }
)

vim.keymap.set(
	"n",
	"<C-l>",
	"<Cmd>Magenta predict-edit<CR>",
	{ silent = true, noremap = true, desc = "Predict/accept edit" }
)

vim.keymap.set(
	"n",
	"<leader>mi",
	":Magenta start-inline-edit<CR>",
	{ silent = true, noremap = true, desc = "Inline edit" }
)

vim.keymap.set(
	"v",
	"<leader>mi",
	":Magenta start-inline-edit-selection<CR>",
	{ silent = true, noremap = true, desc = "Inline edit selection" }
)

vim.keymap.set(
	"n",
	"<leader>mr",
	":Magenta replay-inline-edit<CR>",
	{ silent = true, noremap = true, desc = "Replay last inline edit" }
)

vim.keymap.set(
	"v",
	"<leader>mr",
	":Magenta replay-inline-edit-selection<CR>",
	{ silent = true, noremap = true, desc = "Replay last inline edit on selection" }
)

vim.keymap.set(
	"n",
	"<leader>m.",
	":Magenta replay-inline-edit<CR>",
	{ silent = true, noremap = true, desc = "Replay last inline edit" }
)

vim.keymap.set(
	"v",
	"<leader>m.",
	":Magenta replay-inline-edit-selection<CR>",
	{ silent = true, noremap = true, desc = "Replay last inline edit on selection" }
)
