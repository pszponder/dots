return {
  {
    'L3MON4D3/LuaSnip',
    version = '2.*',
    build = (vim.uv.os_uname().sysname ~= 'Windows' and vim.fn.executable('make') == 1) and 'make install_jsregexp' or nil,
  },
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'L3MON4D3/LuaSnip' },
    event = 'InsertEnter',
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 500 } },
      sources = { default = { 'lsp', 'path', 'snippets' } },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
}
