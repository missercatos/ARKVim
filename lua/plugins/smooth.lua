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

  -- smear-cursor: animated cursor trail
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      cursor_color = nil,
      smear_insert_mode = true,
      stiffness = 0.3,
      trailing_stiffness = 0.15,
      damping = 0.8,
      distance_stop_animating = 0.5,
      smoothing_enabled = function()
        return vim.fn.has("nvim-0.11") == 1
      end,
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

  -- satellite.nvim: scrollbar with diagnostics/git
  {
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    enabled = false,
    opts = {
      current_only = true,
      winblend = 50,
      excluded_filetypes = {},
      handlers = {
        cursor = { enable = false },
      },
    },
  },

  -- dropbar.nvim: VSCode-like breadcrumbs (disabled by default, toggle with <leader>uB)
  {
    "Bekaboo/dropbar.nvim",
    event = "VeryLazy",
    enabled = false,
    opts = {
      bar = {
        enable = function(buf, win, _)
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_win_is_valid(win) then
            return vim.fn.win_gettype(win) == ""
          end
          return false
        end,
      },
    },
  },
}
