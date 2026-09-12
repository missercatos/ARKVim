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

  -- smear-cursor: animated cursor trail (fast preset + longer trail + particles)
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      smear_insert_mode = true,
      -- 透明背景修复：Normal bg=NONE 时拖影会退化成 #303030 实心深色块，
      -- 这里让它融入 kitty 背景色 (#121315)，并避免遮挡目标字符。
      cursor_color = "#e3e2e4",                 -- 拖影颜色（与 kitty cursor 一致）
      transparent_bg_fallback_color = "#121315", -- 透明背景回退色 = kitty background
      never_draw_over_target = true,             -- 不覆盖目标字符（修复字符瞬失）
      -- 头部速度：越大越快，0=不动，1=瞬移
      stiffness = 0.75,               -- default 0.6 (0.6 → 0.75)
      -- 尾部速度：越小尾巴拖得越长（保持不变）
      trailing_stiffness = 0.35,      -- default 0.45
      max_length = 40,                -- default 25 (允许更长的拖影)
      damping = 0.85,                 -- default 0.85
      anticipation = 0.1,             -- default 0.2 (减少反向回摆)
      distance_stop_animating = 0.5,  -- default 0.1 (更早停住)
      time_interval = 10,             -- default 17ms (更高帧率)
      delay_event_to_smear = 1,
      delay_after_key = 5,
      particles_enabled = true,       -- 粒子特效
      -- 粒子更明显：更多、更大存活时间、更长尾迹
      particle_max_num = 200,         -- default 100
      particles_per_second = 400,     -- default 200
      particles_per_length = 2.0,     -- default 1.0
      particle_max_lifetime = 500,    -- default 300 (ms)
      particle_spread = 0.6,          -- default 0.5 (更分散)
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
