local o = vim.opt
vim.g.mapleader = ' '          -- space is the leader key
o.expandtab = true             -- spaces, not tabs
o.shiftwidth = 2               -- 2 spaces per indent level
o.number = true                -- absolute number on the cursor line, relative elsewhere
o.relativenumber = true        -- relative line numbers for fast jumps
o.ignorecase = true            -- search is case-insensitive by default
o.smartcase = true             -- case-sensitive only if i type a capital
o.clipboard = 'unnamedplus'    -- share the system clipboard
o.scrolloff = 16               -- keep cursor away from the screen edge
o.undofile = true              -- persistent undo across sessions
-- o.mouse = 'a'                  -- enable mouse support in all modes
o.mouse = ''                   -- no mouse in nvim; also lets Herdr keep host mouse capture off so Escape isn't swallowed
o.breakindent = true           -- wrapped lines keep the indent of the line they belong to
o.signcolumn = 'yes'           -- always show the sign column so text doesn't shift
o.updatetime = 250             -- faster CursorHold events (diagnostics, git signs)
o.timeoutlen = 300             -- faster which-key popup / mapped sequence timeout
o.splitright = true            -- vertical splits open to the right
o.splitbelow = true            -- horizontal splits open below
o.inccommand = 'split'         -- live preview :substitute results
o.cursorline = true            -- highlight the line the cursor is on
o.confirm = true               -- ask to save instead of erroring on :q with unsaved changes
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- make trailing whitespace/tabs visible

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
