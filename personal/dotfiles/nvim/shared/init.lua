vim.opt.whichwrap = vim.opt.whichwrap + "<,>,h,l,[,]"
vim.wo.number = true
vim.opt.mouse = "a"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true

-- TODO: Confirm if it works
-- Auto choose the swapfile when editing in nvim
-- Update 2025-05-02: Didn't work, at least, when using nvim for working with git commits
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   command = "silent! recover"
-- })

-- Re-read file changes https://neovim.io/doc/user/options.html#'autoread'
vim.o.autoread = true

-- ---------------------------------------------------------------------------
-- GUI-editor compatibility layer
--
-- Goal: the keys muscle memory reaches for in VSCode do the obvious thing here,
-- without giving up any Vim motion or operator. Where a Vim binding is
-- displaced, the replacement for it is noted inline.
--
-- Deliberately terminal-first: nothing below *requires* Cmd, because a terminal
-- can't reliably deliver Cmd to the running program. The <D-...> mappings at the
-- bottom are a bonus for GUI clients and are inert in a terminal.
--
-- Note on modes: 'x' is Visual only (not Select), which is what we want, since
-- 'keymodel' below is configured to start Visual mode rather than Select mode.
-- ---------------------------------------------------------------------------

-- Shift+<arrow> starts/extends a selection and an unshifted arrow collapses it.
-- 'keymodel' is Vim's built-in support for exactly this, so it replaces the 13
-- hand-written <S-arrow> mappings that used to live here. Leaving 'selectmode'
-- empty means these start *Visual* mode, so every operator still works on the
-- selection (Select mode would have made a printable key replace it instead).
-- See `:help 'keymodel'`
vim.opt.keymodel = { 'startsel', 'stopsel' }

-- Yank/delete/put use the system clipboard, like every other editor.
-- Trade-off: d/x/c now also overwrite the system clipboard, because they've
-- always written to the unnamed register. Use "_d etc. where that's unwanted.
vim.opt.clipboard = 'unnamedplus'

-- Undo history survives closing a file (stored under ~/.local/state/nvim/undo)
vim.opt.undofile = true

-- 'backspace' is already indent,eol,start by default in Neovim, so Insert-mode
-- backspace deletes through indent, line breaks and the insert start point
-- without any help. Only the other modes need mapping.
vim.keymap.set('n', '<BS>', 'X')   -- delete the char *before* the cursor (was `x`, which deleted the one under it)
vim.keymap.set('x', '<BS>', '"_d') -- delete the selection without touching the clipboard
vim.keymap.set('n', '<M-BS>', '"_db')
vim.keymap.set('i', '<M-BS>', '<C-w>') -- native "delete word before cursor"

-- Word-wise motion. Alt/Option+arrow is the macOS binding; Ctrl+arrow is the
-- Linux/Windows one, and both are mapped so the same key works everywhere.
-- vim-wordmotion makes these camelCase-aware, like VSCode's word jumping.
for lhs, motion in pairs({ ['Left'] = 'b', ['Right'] = 'w' }) do
  for _, mod in ipairs({ 'M', 'C' }) do
    local key = ('<%s-%s>'):format(mod, lhs)
    vim.keymap.set({ 'n', 'x' }, key, motion)
    -- <C-o> runs one Normal-mode command and drops straight back into Insert
    vim.keymap.set('i', key, '<C-o>' .. motion)
    -- The command line has its own built-in word motions
    vim.keymap.set('c', key, ('<C-%s>'):format(lhs))
  end
end

-- Word-wise selection. 'keymodel' handles plain Shift+arrow but not these, so
-- they stay explicit. Selection uses e/b (which end *on* the word) rather than
-- w, which would spill onto the first character of the following word.
for lhs, motion in pairs({ ['Left'] = 'b', ['Right'] = 'e' }) do
  for _, mod in ipairs({ 'M-S', 'C-S' }) do
    local key = ('<%s-%s>'):format(mod, lhs)
    vim.keymap.set('n', key, 'v' .. motion)
    vim.keymap.set('x', key, motion)
    vim.keymap.set('i', key, '<Esc>v' .. motion)
  end
end

-- Undo / redo.
-- Displaces <C-z> (suspend -> `:suspend`) and <C-y> (scroll up one line, and
-- in Insert mode copy the char above). Vim's own u / <C-r> are untouched.
vim.keymap.set('n', '<C-z>', 'u')
vim.keymap.set('i', '<C-z>', '<C-o>u')
vim.keymap.set('x', '<C-z>', '<Esc>u') -- v_u would lowercase the selection
vim.keymap.set('n', '<C-y>', '<C-r>')
vim.keymap.set('i', '<C-y>', '<C-o><C-r>')
vim.keymap.set('x', '<C-y>', '<Esc><C-r>')
-- Ctrl+Shift+Z as redo, for the VSCode-on-Linux habit. Only terminals speaking
-- an enhanced keyboard protocol can distinguish this from <C-z>; where they
-- can't, it simply never fires.
vim.keymap.set('n', '<C-S-z>', '<C-r>')
vim.keymap.set('i', '<C-S-z>', '<C-o><C-r>')
vim.keymap.set('x', '<C-S-z>', '<Esc><C-r>')

-- Copy / cut / paste.
-- Displaces <C-v> (blockwise Visual -> <C-q>, mapped below, which is Vim's own
-- documented alias) and Normal/Visual <C-c> (interrupt -> <Esc> or <C-[>).
-- Insert-mode <C-c> is left alone so it keeps behaving like <Esc>.
vim.keymap.set('n', '<C-c>', 'yy')
vim.keymap.set('x', '<C-c>', 'y')
vim.keymap.set('n', '<C-x>', 'dd')
vim.keymap.set('x', '<C-x>', 'd') -- a cut: the text lands on the clipboard
vim.keymap.set('n', '<C-v>', 'p')
-- <C-r><C-o> inserts the register literally, so a multi-line paste doesn't get
-- re-indented by 'autoindent'. Insert-mode <C-x> is left alone: it's the prefix
-- for Vim's built-in completion commands.
vim.keymap.set('i', '<C-v>', '<C-r><C-o>+')
-- v_P puts over a selection *without* overwriting the register with the
-- replaced text, which is exactly a GUI editor's paste-over-selection.
vim.keymap.set('x', '<C-v>', 'P')
vim.keymap.set('n', '<C-q>', '<C-v>')

-- Tab / Shift+Tab indent and outdent the selection, keeping it selected.
-- (The old mapping had <S-Tab> indenting, which was backwards.)
vim.keymap.set('x', '<Tab>', '>gv')
vim.keymap.set('x', '<S-Tab>', '<gv')

-- Save. <Cmd> runs the command without changing mode, so unlike the old
-- `<Esc>:w<CR>i` this doesn't drop out of Insert mode or shift the cursor.
vim.keymap.set({ 'n', 'i', 'x' }, '<C-s>', '<Cmd>write<CR>')
vim.keymap.set('c', '<C-s>', '<C-c><Cmd>write<CR>')

-- Cmd equivalents, for GUI front-ends (Neovide, VimR, ...) that can actually
-- deliver <D-...>. A terminal never sends these, so they're harmless there and
-- nothing above depends on them.
vim.keymap.set('n', '<D-z>', 'u')
vim.keymap.set('i', '<D-z>', '<C-o>u')
vim.keymap.set('x', '<D-z>', '<Esc>u')
vim.keymap.set('n', '<D-S-z>', '<C-r>')
vim.keymap.set('i', '<D-S-z>', '<C-o><C-r>')
vim.keymap.set('x', '<D-S-z>', '<Esc><C-r>')
vim.keymap.set('n', '<D-c>', 'yy')
vim.keymap.set('x', '<D-c>', 'y')
vim.keymap.set('n', '<D-x>', 'dd')
vim.keymap.set('x', '<D-x>', 'd')
vim.keymap.set('n', '<D-v>', 'p')
vim.keymap.set('i', '<D-v>', '<C-r><C-o>+')
vim.keymap.set('x', '<D-v>', 'P')
vim.keymap.set({ 'n', 'i', 'x' }, '<D-s>', '<Cmd>write<CR>')

vim.cmd.colorscheme "catppuccin-mocha"
vim.cmd [[
  hi Normal guibg=NONE ctermbg=NONE
  hi NonText guibg=NONE ctermbg=NONE
  hi LineNr guibg=NONE ctermbg=NONE
]]
-- TODO: Confirm if it works
-- Auto restore changes made in nvim
-- require("auto-session").setup {
--   auto_session_enable_last_session = true,
--   auto_restore_enabled = true,
-- }

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Language servers
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {
  capabilities = capabilities,
}
lspconfig.ts_ls.setup {
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
-- See `:help vim.diagnostic.*` for documentation on any of the below functions.
-- Note: `[d` / `]d` are defaults in 0.11+, but are kept here because the defaults
-- jump to the nearest diagnostic of any severity and these are explicit.
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end)
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer.
-- Neovim 0.11 made `grn` (rename), `gra` (code action), `grr` (references),
-- `gri` (implementation), `grt` (type definition), `gO` (document symbol),
-- `K` (hover) and `<C-s>` (signature help, insert mode) default LSP keymaps, and it
-- sets 'omnifunc' automatically — so only the non-default bindings live here.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

    -- match the Normal-mode binding above.
    vim.keymap.set('i', '<C-s>', '<Cmd>write<CR>', opts)
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      vim.print(vim.lsp.buf.list_workspace_folders())
    end, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

require'nvim-treesitter.configs'.setup({
  highlight={enable=true},
})
-- Icons: mini.icons replaces nvim-web-devicons. `mock_nvim_web_devicons` registers
-- it under the old module name so plugins that still `require('nvim-web-devicons')`
-- keep working. See: https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-icons.md
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

require('colorizer').setup()

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


vim.opt.virtualedit = "onemore"