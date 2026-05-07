return {
  {
    "S1M0N38/love2d.nvim",
    cmd = "LoveRun",
    keys = {
      { "<leader>vl", "<cmd>LoveRun<cr>", desc = "运行 Love2D 项目" },
      { "<leader>vs", "<cmd>LoveStop<cr>", desc = "停止 Love2D" },
      { "<leader>vr", "<cmd>LoveRestart<cr>", desc = "重启 Love2D" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = {
                  "love",
                  "rgba",
                },
              },
              workspace = {
                library = {
                  "/usr/share/love",
                  "${3rd}/love2d/library",
                },
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        lua = { "luacheck" },
      },
    },
  },
}
