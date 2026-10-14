return {
  {
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    name = 'catppuccin',
    config = function()
      require('catppuccin').setup({
        flavour = 'mocha',
        transparent_background = vim.uv.os_uname().sysname == 'Darwin'
          or string.find(vim.uv.os_uname().sysname, 'Windows') ~= nil
          or string.find(vim.uv.os_uname().release, 'WSL') ~= nil,
      })

      vim.cmd('colorscheme catppuccin')

      -- Make the dimmed directory path in the Snacks picker readable
      local palette = require('catppuccin.palettes').get_palette('mocha')
      vim.api.nvim_set_hl(0, 'SnacksPickerDir', { fg = palette.overlay1 })
    end,
  },
}
