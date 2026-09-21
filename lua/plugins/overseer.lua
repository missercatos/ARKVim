return {
  {
    "stevearc/overseer.nvim",
    lazy = true,
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerRun",
      "OverseerTaskAction",
      "OverseerLoadBundle",
      "OverseerDeleteBundle",
      "OverseerClearCache",
    },
    -- 自动编译/运行：任务面板 + 运行任务（识别 cargo/npm/make/gradle/... 的内置模板）
    keys = {
      { "<leader>Bo", "<cmd>OverseerToggle<CR>", desc = "任务面板 (Overseer)" },
      { "<leader>BR", "<cmd>OverseerRun<CR>", desc = "运行任务 (Overseer)" },
      { "<leader>Bq", "<cmd>OverseerClose<CR>", desc = "关闭任务面板" },
    },
    opts = {
      dap = false,
      task_list = {
        keymaps = {
          ["<C-j>"] = false,
          ["<C-k>"] = false,
        },
      },
      -- 把 watch 构建也接进来：保存时的自动构建走 arkvim.build 的 <leader>Bw
      task_win = { show_help = true },
    },
  },
}
