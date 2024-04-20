vim.opt.whichwrap = vim.opt.whichwrap + "<,>,h,l,[,]"
vim.wo.number = true
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
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
vim.api.nvim_set_keymap('v', '<S-Tab>', '>', { noremap = true })

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

vim.api.nvim_set_keymap('n', '<C-s>', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-s>', '<Esc>:w<CR>i', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-s>', '<Esc>:w<CR>gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('c', '<C-s>', '<C-c>:w<CR>', { noremap = true, silent = true })

vim.cmd.colorscheme "catppuccin-mocha"
vim.cmd [[
  hi Normal guibg=NONE ctermbg=NONE
  hi NonText guibg=NONE ctermbg=NONE
  hi LineNr guibg=NONE ctermbg=NONE
]]

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Language servers
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {
  capabilities = capabilities,
}
lspconfig.tsserver.setup {
  capabilities = capabilities,
}
lspconfig.rust_analyzer.setup {
  -- Server-specific settings. See `:help lspconfig-setup`
  settings = {
    ['rust-analyzer'] = {},
  },
  capabilities = capabilities,
}
lspconfig.lua_ls.setup {
  capabilities = capabilities,
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

require'nvim-treesitter.configs'.setup({
  highlight={enable=true},
})

vim.o.smartcase = false

local rainbow_delimiters = require 'rainbow-delimiters'
vim.g.nvim_autopairs = {}
vim.g.rainbow_delimiters = {
    strategy = {
        [''] = rainbow_delimiters.strategy['global'],
        vim = rainbow_delimiters.strategy['local'],
    },
    query = {
        [''] = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
    },
    highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
    },
}

vim.opt.list = true
vim.opt.termguicolors = true
vim.cmd [[highlight IndentBlanklineIndent1 guifg=#E06C75 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E5C07B gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent3 guifg=#98C379 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent4 guifg=#56B6C2 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent5 guifg=#61AFEF gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent6 guifg=#C678DD gui=nocombine]]

vim.g.ident_blankline = {
  space_char_blankline = " ",
  char_highlight_list = {
      "IndentBlanklineIndent1",
      "IndentBlanklineIndent2",
      "IndentBlanklineIndent3",
      "IndentBlanklineIndent4",
      "IndentBlanklineIndent5",
      "IndentBlanklineIndent6",
  },
}

local cmp = require'cmp'
local lspkind = require('lspkind')

local entry_filter = function(entry, ctx)
  local length = #entry:get_completion_item().label

  -- Example filter: only include entries with a label length less than 10 characters
  if length > 3 then
    return true
  else
    return false
  end
end

require'lsp_signature'.setup({
  -- Configure based on your preference
  bind = true, -- This is mandatory, otherwise border config won't get registered.
  handler_opts = {
    border = "rounded" -- Double, single, rounded, solid, shadow, none
  },
})

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    end,
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol', -- show only symbol annotations
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)

      -- The function below will be called before any actual modifications from lspkind
      -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      before = function (entry, vim_item)
        return vim_item
      end
    })
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
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lsp_document_symbol'},
    { name = 'treesitter' },
    { name = 'buffer', entry_filter = entry_filter },
    { name = 'rg',
              option = {
                additional_arguments = "--max-depth 2 --one-file-system",
              }
                    , keyword_length = 5 },
    {
      name = 'vsnip',
      -- Only want snippets for new lines
      keyword_pattern = [[^\s*]] }, -- For vsnip users.
    { name = 'path' },
    { name = 'git' },
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

