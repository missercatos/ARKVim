local terminal = require("arkvim.terminal")
local cava = require("arkvim.cava-theme").read_cava_colors()

-- 富终端（kitty + 能读到背景色配置）：透明背景 + 自定义配色 + 终端光标色。
-- 非富终端一律走 tokyonight 保底：不透明背景、原厂语法色。
local rich = terminal.rich()

-- 仅富终端生效的语法色
local C = {
  comment = "#7a8499",    -- 注释：柔和灰蓝，与关键字/正文明显区分
  constant = "#c2a878",   -- 枚举/常量：柔和琥珀，与注释不同色
  cursorline = "#1f2335", -- 行高亮：浅淡，不压暗语法
  ghost = "#8a94a8",      -- 补全幽灵文本：淡灰（参考注释色深），能看清又不与已输入内容混淆
}

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = rich,
      styles = rich and { sidebars = "transparent", floats = "transparent" }
        or { sidebars = "dark", floats = "dark" },
      on_colors = function(colors)
        if rich and cava then
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
        if rich then
          colors.bg = "NONE"
          colors.bg_dark = "NONE"
          colors.bg_sidebar = "NONE"
          colors.bg_statusline = "NONE"
        end
      end,
      on_highlights = function(hl)
        if not rich then
          return
        end

        -- 语法色：注释与枚举/常量改成不同颜色，且都不太鲜艳
        hl.Comment = { fg = C.comment }
        hl.Constant = { fg = C.constant }
        hl["@constant"] = { fg = C.constant }
        hl["@constant.builtin"] = { fg = C.constant }

        -- 行高亮：编辑区 + 文件树，浅淡不抢眼
        hl.CursorLine = { bg = C.cursorline }
        hl.CursorColumn = { bg = "NONE" }
        hl.SnacksPickerListCursorLine = { bg = C.cursorline }
        hl.SnacksPickerCursorLine = { bg = C.cursorline }
        hl.SnacksPickerBoxCursorLine = { bg = C.cursorline }
        hl.SnacksPickerInputCursorLine = { bg = C.cursorline }
        hl.SnacksPickerPreviewCursorLine = { bg = C.cursorline }

        -- 光标颜色（与 kitty cursor / 拖影 cursor_color 保持一致）
        hl.Cursor = { fg = terminal.cursor_text_color, bg = terminal.cursor_color }

        -- 补全菜单：菜单底 + 选中项要清晰可辨
        hl.Pmenu = { fg = "#c0caf5", bg = "#16161e" }
        hl.PmenuSel = { fg = "#c0caf5", bg = "#2f3d5e", bold = true }
        hl.PmenuSbar = { bg = "#16161e" }
        hl.PmenuThumb = { bg = "#2f3d5e" }
        -- 补全幽灵文本（blink.cmp）：淡灰，能看清又不与已输入内容混淆
        hl.BlinkCmpGhostText = { fg = C.ghost }

        -- 透明背景
        hl.Normal = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalNC = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalFloat = { bg = "NONE", ctermbg = "NONE" }
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
