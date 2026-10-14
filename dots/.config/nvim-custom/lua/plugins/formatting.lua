return {
  {
    'stevearc/conform.nvim',
    keys = {
      {
        '<leader>lf',
        function() require('conform').format({ async = true }) end,
        mode = { 'n', 'v' },
        desc = 'Format Buffer',
      },
    },
    opts = {
      notify_on_error = false,
      default_format_opts = { lsp_format = 'fallback' },
      formatters_by_ft = {
        lua = { 'stylua' },
      },
    },
  },
}
