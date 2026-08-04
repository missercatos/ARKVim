-- 战术终端：去除花里胡哨（图标装饰/动效），仅保留功能
-- 仅在 foot/alacritty（vim.g.tactical）内生效，其他终端零影响
if not vim.g.tactical then
  return {}
end

local tactical_keys = {
  { icon = "> ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
  { icon = "> ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
  { icon = "> ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
  { icon = "> ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
  { icon = "> ", key = "l", desc = "Lazy", action = ":Lazy" },
  { icon = "> ", key = "x", desc = "Exit", action = ":qa" },
}

local tactical_kinds = {
  Array = "A", Boolean = "B", Class = "C", Color = "C", Control = "C",
  Collapsed = ">", Constant = "K", Constructor = "N", Copilot = "G",
  Enum = "E", EnumMember = "E", Event = "E", Field = "F", File = "F",
  Folder = "D", Function = "F", Interface = "I", Key = "K", Keyword = "K",
  Method = "M", Module = "M", Namespace = "N", Null = "N", Number = "N",
  Object = "O", Operator = "O", Package = "P", Property = "P",
  Reference = "R", Snippet = "S", String = "S", Struct = "S",
  Text = "T", TypeParameter = "T", Unit = "U", Unknown = "?",
  Value = "V", Variable = "V",
}

return {
  -- 图标化状态栏 → 原生极简状态栏（见 options.lua）
  { "nvim-lualine/lualine.nvim", enabled = false },
  -- 图标化标签栏 → 原生 tabline
  { "akinsho/bufferline.nvim", enabled = false },
  -- 命令行动效弹窗 → 原生 cmdline
  { "folke/noice.nvim", enabled = false },
  -- 启动页纯 ASCII 大 ARKVIM 头（固定磷光绿，无 lazyvim 标题/无图像），关平滑滚动/图像/动效
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        sections = {
          {
            section = "terminal",
            cmd = vim.fn.stdpath("config") .. "/lua/arkvim/header-tactical.sh",
            height = 6,
            padding = 0,
            indent = 0,
            ttl = 0,
          },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup", padding = 1 },
        },
        keys = tactical_keys,
      })
      opts.scroll = vim.tbl_deep_extend("force", opts.scroll or {}, {
        enabled = false,
      })
      opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
        enabled = false,
      })
      opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
        enabled = false,
      })
    end,
  },
  {
    "folke/snacks.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      -- picker 隐藏文件图标（无 Nerd Font），kind 图标换 ASCII
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        icons = {
          files = { enabled = false },
          kinds = tactical_kinds,
        },
      })
    end,
  },
}
