local cava = require("arkvim.cava-theme").read_cava_colors()

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
        if cava then
          colors.cyan = cava[1] or colors.cyan
          colors.blue = cava[2] or colors.blue
          colors.purple = cava[3] or colors.purple
          colors.red = cava[4] or colors.red
          colors.orange = cava[5] or colors.orange
        end
        colors.bg = "NONE"
        colors.bg_dark = "NONE"
        colors.bg_sidebar = "NONE"
        colors.bg_statusline = "NONE"
      end,
      on_highlights = function(hl)
        hl.Comment = { fg = "#a8b2e0" }
        hl.Normal = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalNC = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalFloat = { bg = "NONE", ctermbg = "NONE" }
        hl.Pmenu = { bg = "NONE", ctermbg = "NONE" }
        hl.PmenuSel = { bg = "NONE", ctermbg = "NONE" }
        hl.PmenuSbar = { bg = "NONE", ctermbg = "NONE" }
        hl.PmenuThumb = { bg = "NONE", ctermbg = "NONE" }
        hl.TabLine = { bg = "NONE", ctermbg = "NONE" }
        hl.TabLineFill = { bg = "NONE", ctermbg = "NONE" }
        hl.TabLineSel = { bg = "NONE", ctermbg = "NONE" }
      end,
    },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
        enabled = true,
      })
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
          { section = "startup" },
        },
      })
      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        terminal = {
          wo = { winblend = 0 },
        },
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        once = true,
        callback = function()
          vim.defer_fn(function()
            local file = vim.fn.stdpath("config") .. "/lua/arkvim/"
            if vim.fn.filereadable(file) == 1 then
              pcall(function()
                Snacks.image.placement.new(vim.api.nvim_get_current_buf(), file, {
                  auto_resize = true,
                  max_width = 45,
                  max_height = 15,
                  on_update_pre = function(p)
                    local img = Snacks.image.util.pixels_to_cells(Snacks.image.util.dim(file))
                    p.opts.pos = {
                      13,
                      math.max(64, math.floor((vim.o.columns - img.width) / 2) - 5),
                    }
                    local ok = vim.o.columns >= 130 and vim.o.lines >= 8 + img.height + 3
                    if ok then
                      p:show()
                    else
                      p:hide()
                    end
                  end,
                })
              end)
            end
          end, 200)
        end,
      })
    end,
  },
}
