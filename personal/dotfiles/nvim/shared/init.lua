vim.opt.whichwrap = vim.opt.whichwrap + "<,>,h,l,[,]"
vim.wo.number = true
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.api.nvim_set_keymap('v', '<S-Up>', '<Up>', { noremap = true; })
vim.api.nvim_set_keymap('v', '<S-Down>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('v', '<S-Left>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('v', '<S-Right>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<S-Up>', '<esc>v<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<S-Down>', '<esc>v<Down>', { noremap = true })
vim.api.nvim_set_keymap('i', '<S-Left>', '<esc>v<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<S-Right>', '<esc>v<Right>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Up>', '<esc>v<Up>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Down>', '<esc>v<Down>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Left>', '<esc>v<Left>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Right>', '<esc>v<Right>', { noremap = true })

vim.api.nvim_set_keymap('n', '<S-Right>', '<esc>v<Right>', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Right>', '<esc>v<Right>', { noremap = true })

-- Alt+Left Arrow for skipping backward
vim.api.nvim_set_keymap('v', '<BS>', 'd', {noremap = true})
vim.api.nvim_set_keymap('n', '<A-BS>', 'xdb', {noremap = true})
vim.api.nvim_set_keymap('n', '<BS>', 'x', {noremap = true})
vim.api.nvim_set_keymap('i', '<A-BS>', '<Esc><Right>dbi', {noremap = true})

vim.api.nvim_set_keymap('v', '<M-Left>', 'b', {noremap = true})
vim.api.nvim_set_keymap('n', '<M-Left>', 'b', {noremap = true})
vim.api.nvim_set_keymap('i', '<M-Left>', '<Esc>bi', {noremap = true})
vim.api.nvim_set_keymap('c', '<M-Left>', '<Left>', {noremap = true})

-- Alt+Right Arrow for skipping forward
vim.api.nvim_set_keymap('v', '<M-Right>', 'e', {noremap = true})
vim.api.nvim_set_keymap('n', '<M-Right>', 'e', {noremap = true})
vim.api.nvim_set_keymap('i', '<M-Right>', '<Esc>ei<Right>', {noremap = true})
vim.api.nvim_set_keymap('c', '<M-Right>', '<Right>', {noremap = true})

vim.cmd.colorscheme "catppuccin-mocha"
vim.cmd [[
  hi Normal guibg=NONE ctermbg=NONE
  hi NonText guibg=NONE ctermbg=NONE
  hi LineNr guibg=NONE ctermbg=NONE
]]

--require('Comment').setup()
require("neoconf").setup({
  -- override any of the default settings here
})

-- Language servers
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {}
lspconfig.tsserver.setup {}
lspconfig.rust_analyzer.setup {
  -- Server-specific settings. See `:help lspconfig-setup`
  settings = {
    ['rust-analyzer'] = {},
  },
}


-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
--

require'nvim-treesitter.configs'.setup({
  highlight={enable=true},

  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
    -- colors = {}, -- table of hex strings
    -- termcolors = {} -- table of colour name strings
  }
})

local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
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
    ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
    { name = 'treesitter' },
    { name = 'rg'},
    { name = 'nvim_lsp_document_symbol'},
    { name = 'nvim_lsp_signature_help' },
  }, {
    { name = 'buffer' },
  })
})

require("cmp").setup({
  enabled = function()
    return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
        or require("cmp_dap").is_dap_buffer()
  end
})

require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
  sources = {
    { name = "dap" },
  },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("nvim-lightbulb").setup({
  autocmd = { enabled = true }
})
require("ssr").setup {
  border = "rounded",
  min_width = 50,
  min_height = 5,
  max_width = 120,
  max_height = 25,
  keymaps = {
    close = "q",
    next_match = "n",
    prev_match = "N",
    replace_confirm = "<cr>",
    replace_all = "<leader><cr>",
  },
}

vim.keymap.set({ "n", "x" }, "<leader>sr", function() require("ssr").open() end)

