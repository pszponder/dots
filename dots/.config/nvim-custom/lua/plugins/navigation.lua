return {
  {
    'stevearc/oil.nvim',
    opts = { view_options = { show_hidden = true } },
    keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File Browser' } },
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },
      { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
      { 'gr', function() Snacks.picker.lsp_references() end, desc = 'Goto References' },
      { 'gi', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
      { 'gO', function() Snacks.picker.lsp_symbols() end, desc = 'Document Symbols' },
      { 'gW', function() Snacks.picker.lsp_symbols({ workspace = true }) end, desc = 'Workspace Symbols' },
    },
  },
}
