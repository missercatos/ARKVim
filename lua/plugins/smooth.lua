local terminal = require("arkvim.terminal")

-- 拖影/粒子颜色统一由 arkvim/terminal.lua 的 cursor_color 提供
local CURSOR_COLOR = terminal.cursor_color

-- 终端自带拖影（kitty cursor_trail > 0）时，关闭 nvim 侧拖影插件，避免双重拖影。
-- 想用 nvim 的拖影+粒子：把 kitty.conf 里 cursor_trail 设为 0 即可。
local native_trail = terminal.has_native_cursor_trail()

return {
  -- mini.surround: sa/sd/sr surround operations
  {
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    opts = {
      n_lines = 50,
      search_method = "cover_or_nearest",
    },
  },

  -- mini.comment: gc/gb commenting
  {
    "nvim-mini/mini.comment",
    event = "VeryLazy",
    opts = {},
  },

  -- smear-cursor: animated cursor trail (fast preset + smaller trail + particles)
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    -- 终端自带拖影时关闭本插件（避免双重拖影）
    enabled = not native_trail,
    opts = {
      smear_insert_mode = true,
      -- 颜色：改顶部 CURSOR_COLOR 即可
      cursor_color = CURSOR_COLOR,
      cursor_color_insert_mode = CURSOR_COLOR,
      -- 透明背景：用探测到的终端背景色，避免退化成实心深色块
      transparent_bg_fallback_color = terminal.background() or "#303030",
      never_draw_over_target = true,  -- 不覆盖目标字符（修复字符瞬失）
      -- 头部速度：越大越快，0=不动，1=瞬移
      stiffness = 0.75,               -- default 0.6
      -- 尾部速度：越小尾巴拖得越长
      trailing_stiffness = 0.35,      -- default 0.45
      max_length = 15,                -- default 25（拖影更小）
      damping = 0.85,                 -- default 0.85
      anticipation = 0.1,             -- default 0.2 (减少反向回摆)
      distance_stop_animating = 0.8,  -- default 0.1 (更早停住)
      time_interval = 10,             -- default 17ms (更高帧率)
      delay_event_to_smear = 1,
      delay_after_key = 5,
      particles_enabled = true,       -- 粒子特效
      -- 粒子更明显：更多、存活更久、更分散
      particle_max_num = 200,         -- default 100
      particles_per_second = 400,     -- default 200
      particles_per_length = 2.0,     -- default 1.0
      particle_max_lifetime = 500,    -- default 300 (ms)
      particle_spread = 0.6,          -- default 0.5
      particles_over_text = false,    -- 不画在文字上，避免字符被遮挡
    },
  },

  -- rainbow-delimiters: colored bracket pairs
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = { [""] = rainbow.strategy["global"] },
        query = { [""] = "rainbow-delimiters" },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
      vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#e06c75" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#e5c07b" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#61afef" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#d19a66" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#c678dd" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#56b6c2" })
    end,
  },

  -- dial.nvim: enhanced <C-a>/<C-x>
  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>", function() require("dial.map").inc_normal() end, desc = "Increment" },
      { "<C-x>", function() require("dial.map").dec_normal() end, desc = "Decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.new("%Y-%m-%d"),
          augend.constant.new("true", "false"),
          augend.constant.new("True", "False"),
          augend.constant.new("YES", "NO"),
          augend.constant.new("on", "off"),
        },
      })
    end,
  },

  -- inc-rename: live rename preview
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      { "<leader>rn", function() return ":IncRename " .. vim.fn.expand("<cword>") end, desc = "Rename (live)", expr = true },
    },
    opts = {},
  },

  -- yanky.nvim: yank ring
  {
    "gbprod/yanky.nvim",
    keys = {
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put After" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Before" },
      { "[y", "<Plug>(YankyCycleForward)", desc = "Yank Ring Next" },
      { "]y", "<Plug>(YankyCycleBackward)", desc = "Yank Ring Prev" },
    },
    opts = {
      ring = { history_length = 50 },
      highlight = { timer = 200 },
    },
  },

  -- treesj: split/join code blocks
  {
    "Wansmer/treesj",
    keys = {
      { "<leader>cj", function() require("treesj").toggle() end, desc = "Toggle split/join" },
      { "<leader>cJ", function() require("treesj").toggle({ split = { recursive = true } }) end, desc = "Toggle split/join (recursive)" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      use_default_keymaps = false,
      max_join_length = 150,
    },
  },
}
