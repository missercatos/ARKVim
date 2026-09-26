-- Extra neotest adapters not covered by LazyVim's lang extras.
-- Go/Python/Ruby adapters already come from LazyVim's lang/go, lang/python, lang/ruby.
-- This spec merges into neotest's opts (it does NOT call neotest.setup()).
local specs = {}

-- 实时测试：neotest watch（保存/改动时自动重跑，需要 LSP 附加）
-- neotest 找不到适配器/位置时，自动退回「保存触发测试」（arkvim.build 的 watch）
table.insert(specs, {
  "nvim-neotest/neotest",
  keys = {
    {
      "<leader>tw",
      function()
        if not require("arkvim.test").watch("file") then
          vim.notify("neotest 无法 watch 本文件（无适配器/非测试文件/LSP 未附加）\n→ 退回「保存自动测试」(<leader>BW)",
            vim.log.levels.WARN, { title = "ARKVIM" })
          require("arkvim.build").toggle_watch("test")
        end
      end,
      desc = "Watch File (实时测试)",
    },
    {
      "<leader>tW",
      function()
        if not require("arkvim.test").watch("project") then
          vim.notify("neotest 无法 watch 本项目（无适配器/LSP 未附加）\n→ 退回「保存自动测试」(<leader>BW)",
            vim.log.levels.WARN, { title = "ARKVIM" })
          require("arkvim.build").toggle_watch("test")
        end
      end,
      desc = "Watch Project (实时测试)",
    },
    { "<leader>tq", function() require("neotest").watch.stop() end, desc = "Stop All Watches" },
    { "<leader>ti", function() require("arkvim.test").status() end, desc = "实时测试: 诊断" },
  },
})

if vim.fn.executable("node") == 1 then
  table.insert(specs, {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "marilari88/neotest-vitest" },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
    },
  })
end

if vim.fn.executable("java") == 1 then
  table.insert(specs, {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "rcasia/neotest-java" },
    opts = {
      adapters = {
        ["neotest-java"] = {},
      },
    },
  })
end

return specs
