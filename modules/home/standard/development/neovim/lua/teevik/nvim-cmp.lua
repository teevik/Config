-- nvim-cmp
vim.pack.add({
    "https://github.com/hrsh7th/nvim-cmp",
    "https://github.com/hrsh7th/cmp-nvim-lsp",
    "https://github.com/hrsh7th/cmp-buffer",
    "https://github.com/hrsh7th/cmp-path",
    "https://github.com/hrsh7th/cmp-cmdline"
    -- "https://github.com/hrsh7th/cmp-vsnip"
    -- "https://github.com/hrsh7th/vim-vsnip"
}, { confirm = false })

local cmp = require("cmp")

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
            vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)

            -- For `mini.snippets` users:
            -- local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
            -- insert({ body = args.body }) -- Insert at cursor
            -- cmp.resubscribe({ "TextChangedI", "TextChangedP" })
            -- require("cmp.config").set_onetime({ sources = {} })
        end,
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' }, -- For vsnip users.
        -- { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
    }, {
        { name = 'buffer' },
        {
            name = "lazydev",
            group_index = 0, -- set group index to 0 to skip loading LuaLS completions
        }
    })
})

-- -- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
-- -- Set configuration for specific filetype.
-- cmp.setup.filetype('gitcommit', {
--   sources = cmp.config.sources({
--     { name = 'git' },
--   }, {
--     { name = 'buffer' },
--   })
-- })

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities()


-- INFO: completion engine
-- vim.pack.add({ "https://github.com/saghen/blink.cmp" }, { confirm = false })

-- require("blink.cmp").setup({
--   completion = {
--     documentation = {
--       auto_show = true,
--     },
--   },

--   sources = {
--     -- add lazydev to your completion providers
--     default = { "lazydev", "lsp", "path", "snippets", "buffer" },
--     providers = {
--       lazydev = {
--         name = "LazyDev",
--         module = "lazydev.integrations.blink",
--         -- make lazydev completions top priority (see `:h blink.cmp`)
--         score_offset = 100,
--       },
--     },
--   },

--   keymap = {
--     ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
--     ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
--     ['<C-y>'] = { 'select_and_accept', 'fallback' },
--     ['<C-e>'] = { 'cancel', 'fallback' },

--     ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
--     ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
--     ['<CR>'] = { 'select_and_accept', 'fallback' },
--     ['<Esc>'] = { 'cancel', 'hide_documentation', 'fallback' },

--     ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },

--     ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
--     ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

--     ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
--   },

--   fuzzy = {
--     implementation = "lua",
--   },
-- })
