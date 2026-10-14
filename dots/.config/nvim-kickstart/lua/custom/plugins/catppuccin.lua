return {
  -- Catppuccin main theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte | frappe | macchiato | mocha
        transparent_background = false,

        integrations = {
          treesitter = true,
          gitsigns = true,
          telescope = true,
          mason = true,
          cmp = true,
          nvimtree = true,   -- set false if you use Neo-tree instead
          neotree = false,   -- set true if you use Neo-tree instead of NvimTree
          notify = true,
          noice = true,
          dap = true,
          dap_ui = true,
          which_key = true,
          indent_blankline = {
            enabled = true,
            colored_indent_levels = false,
          },
        },
      })

      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Lualine theming
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = "catppuccin"
    end,
  },

  -- Telescope refinements (borders, icons)
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        prompt_prefix = "   ",
        selection_caret = " ",
        borderchars = {
          prompt  = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          results = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
      })
    end,
  },

  -- Treesitter highlight guarantee (Catppuccin provides colors)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      opts.highlight.enable = true
    end,
  },

  -- NvimTree UI enhancements (works with Catppuccin highlights)
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      renderer = {
        highlight_git = true,
        highlight_opened_files = "name",
      },
      filters = {
        dotfiles = false,
      },
    },
  },

  -- Noice + Notify integrated styling
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
    },
  },
}
