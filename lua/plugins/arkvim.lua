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
          -- cava 渐变里可能有很暗的颜色（如 #233954），直接当语法前景会看不清。
          -- 只取亮度足够的颜色作为强调色，其余保留 tokyonight 原色。
          local function luminance(hex)
            local r = tonumber(hex:sub(2, 3), 16) or 0
            local g = tonumber(hex:sub(4, 5), 16) or 0
            local b = tonumber(hex:sub(6, 7), 16) or 0
            return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
          end
          local bright = {}
          for _, c in ipairs(cava) do
            if type(c) == "string" and #c == 7 and luminance(c) >= 0.5 then
              bright[#bright + 1] = c
            end
          end
          colors.cyan = bright[1] or colors.cyan
          colors.blue = bright[2] or colors.blue
          colors.purple = bright[3] or colors.purple
          if bright[4] then colors.red = bright[4] end
          if bright[5] then colors.orange = bright[5] end
        end
        colors.bg = "NONE"
        colors.bg_dark = "NONE"
        colors.bg_sidebar = "NONE"
        colors.bg_statusline = "NONE"
      end,
      on_highlights = function(hl)
        hl.Comment = { fg = "#a8b2e0" }
        -- 透明背景下去掉 cursorline/cursorcolumn 的实心色块（会随光标拖动、压暗整行）
        hl.CursorLine = { bg = "NONE", ctermbg = "NONE" }
        hl.CursorColumn = { bg = "NONE", ctermbg = "NONE" }
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
