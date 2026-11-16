-- AI 集成：sidekick（按需加载，不占用启动/插入模式资源）
return {
  {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    keys = {
      {
        "<leader>As",
        function()
          require("sidekick").toggle()
        end,
        desc = "Sidekick Toggle",
      },
      {
        "<leader>Aa",
        function()
          require("sidekick").ask()
        end,
        desc = "Sidekick Ask",
      },
    },
    dependencies = { "folke/snacks.nvim" },
    config = true,
  },
}
