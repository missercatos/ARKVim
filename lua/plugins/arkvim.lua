local themes = require("arkvim.themes")
vim.g.arkvim_colors = themes.themes[themes.current].colors

vim.keymap.set("n", "<Leader>t1", function() themes.switch("amya") end, { desc = "Theme: amya" })
vim.keymap.set("n", "<Leader>t2", function() themes.switch("amyaa") end, { desc = "Theme: amyaa" })
vim.keymap.set("n", "<Leader>t3", function() themes.switch("kastic") end, { desc = "Theme: kastic" })
vim.keymap.set("n", "<Leader>t4", function() themes.switch("mon") end, { desc = "Theme: mon" })
vim.keymap.set("n", "<Leader>tn", function() themes.next() end, { desc = "Next theme" })
vim.keymap.set("n", "<Leader>tp", function() themes.prev() end, { desc = "Previous theme" })

return {
  {
    "LazyVim/LazyVim",
    opts = {
      extras = {},
    },
  },
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
        local tc = vim.g.arkvim_colors or {}
        colors.bg = "NONE"
        colors.bg_dark = "NONE"
        colors.bg_sidebar = "NONE"
        colors.bg_statusline = "NONE"
        colors.bg_float = tc.bg_float or "#161b22"
        colors.bg_highlight = tc.bg_highlight or "#1c2333"
        colors.bg_popup = tc.bg_popup or "#161b22"
        colors.bg_search = tc.bg_search or "#2a3520"
        colors.bg_visual = tc.bg_visual or "#252b36"
        colors.fg = tc.fg or "#c8ccd4"
        colors.fg_dark = tc.fg_dark or "#8b949e"
        colors.fg_float = tc.fg_float or "#d4d8de"
        colors.fg_gutter = tc.fg_gutter or "#484f58"
        colors.fg_sidebar = tc.fg_sidebar or "#b0b8c0"
        colors.border = tc.border or "#30363d"
        colors.comment = tc.comment or "#6e7681"
        colors.dark3 = tc.dark3 or "#30363d"
        colors.dark5 = tc.dark5 or "#21262d"
        colors.blue = tc.blue or "#58a6ff"
        colors.blue1 = tc.blue1 or "#79c0ff"
        colors.blue2 = tc.blue2 or "#388bfd"
        colors.blue5 = tc.blue5 or "#58a6ff"
        colors.blue6 = tc.blue6 or "#1f6feb"
        colors.blue7 = tc.blue7 or "#a5d6ff"
        colors.cyan = tc.cyan or "#4fc3f7"
        colors.green = tc.green or "#7ec994"
        colors.green1 = tc.green1 or "#a5d6a2"
        colors.green2 = tc.green2 or "#56b37a"
        colors.teal = tc.teal or "#4db6ac"
        colors.magenta = tc.magenta or "#c792ea"
        colors.magenta2 = tc.magenta2 or "#ddbaf5"
        colors.orange = tc.orange or "#e8a850"
        colors.purple = tc.purple or "#b39ddb"
        colors.red = tc.red or "#f07078"
        colors.red1 = tc.red1 or "#ff8e96"
        colors.yellow = tc.yellow or "#e5c07b"
        colors.git = tc.git or {
          change = tc.orange or "#e8a850",
          add = tc.green or "#7ec994",
          delete = tc.red or "#f07078",
        }
        colors.gitSigns = tc.gitSigns or {
          change = tc.orange or "#e8a850",
          add = tc.green or "#a5d6a2",
          delete = tc.red or "#ff8e96",
        }
        colors.diff = tc.diff or {
          add = "#12261a",
          change = "#2a2412",
          delete = "#2a1518",
          text = "#161b22",
        }
      end,
      on_highlights = function(hl, colors)
        hl.Normal = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalNC = { bg = "NONE", ctermbg = "NONE" }
        hl.NormalFloat = { bg = "NONE", ctermbg = "NONE" }
        hl["@punctuation.bracket"] = { fg = "#8b949e" }
        hl["@punctuation.delimiter"] = { fg = "#b0b8c0" }
        hl["@punctuation.special"] = { fg = "#c8ccd4" }
        hl["@constructor"] = { fg = colors.yellow }
        hl["@lsp.type.class.cpp"] = { fg = colors.yellow }
        hl["@lsp.type.enumMember.cpp"] = { fg = colors.yellow }
        hl["@lsp.type.function.cpp"] = { fg = colors.yellow }
        hl["@lsp.typemod.function.class.cpp"] = { fg = colors.yellow }
        hl["@keyword.operator.cpp"] = { fg = colors.yellow }
        hl["@keyword.return.cpp"] = { fg = colors.yellow }
        hl["Delimiter"] = { fg = "#8b949e" }
        hl["Special"] = { fg = colors.orange }
        hl["NeoTreeDirectoryName"] = { fg = "#e6edf3" }
        hl["NeoTreeDirectoryIcon"] = { fg = "#e6edf3" }
        hl["NeoTreeDotfile"] = { fg = "#d4d8de" }
        hl["NeoTreeDimText"] = { fg = "#d4d8de" }
        hl["NeoTreeFileName"] = { fg = "#e6edf3" }
        hl["NeoTreeGitIgnored"] = { fg = "#c8ccd4" }
        hl["SnacksExplorerDimmed"] = { fg = "#c8ccd4" }
        hl["SnacksExplorerDirectory"] = { fg = "#e6edf3" }
        hl["SnacksExplorerFile"] = { fg = "#d4d8de" }
        hl["SnacksExplorerGitIgnored"] = { fg = "#b0b8c0" }
        hl["SnacksPickerDirectory"] = { fg = "#e6edf3" }
        hl["SnacksPickerFile"] = { fg = "#d4d8de" }
        hl["SnacksPickerDir"] = { fg = "#b0b8c0" }
        hl["SnacksPickerPathHidden"] = { fg = "#c8ccd4" }
        hl["SnacksPickerPathIgnored"] = { fg = "#b0b8c0" }
      end,
    },
  },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local t = themes.themes[themes.current]
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {})
      opts.dashboard.sections = {
        {
          section = "terminal",
          cmd = vim.fn.stdpath("config") .. "/art_show.sh",
          height = 20,
          padding = 0,
          indent = 0,
          ttl = 0,
        },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      }
      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        terminal = {
          wo = { winblend = 0 },
        },
      })
    end,
  },
}
