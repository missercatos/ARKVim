return {
  -- flutter-tools.nvim: Flutter dev with hot reload
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = { "dart" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("flutter-tools").setup({
        widget_guides = { enabled = true },
        closing_tags = { enabled = true },
        dev_log = { enabled = true },
        dev_tools = { autostart = false, auto_open_bridge = true },
        outline = { auto_open = false },
        debugger = { enabled = false },
      })
    end,
  },

  -- remote-nvim.nvim: remote SSH development
  {
    "amitds1997/remote-nvim.nvim",
    cmd = { "RemoteStart", "RemoteStop", "RemoteInfo", "RemoteCleanup" },
    keys = {
      { "<leader>Xr", "<cmd>RemoteStart<CR>", desc = "远程开发" },
    },
    config = true,
  },
}
