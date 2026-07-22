return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      style = "night",
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        colors.bg = "NONE"
        colors.bg_dark = "NONE"
        colors.bg_sidebar = "NONE"
        colors.bg_statusline = "NONE"
      end,
      on_highlights = function(hl)
        hl.Normal = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalNC = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalFloat = { bg = "NONE", ctermbg = "NONE" }
      end,
    },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        sections = {
          {
            section = "terminal",
            cmd = vim.fn.stdpath("config") .. "/lua/arkvim/header.sh",
            height = 8,
            padding = 0,
            indent = 0,
            ttl = 0,
          },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      })
      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        terminal = {
          wo = { winblend = 0 },
        },
      })
    end,
  },
}
