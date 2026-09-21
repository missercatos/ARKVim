-- Extra neotest adapters not covered by LazyVim's lang extras.
-- Go/Python/Ruby adapters already come from LazyVim's lang/go, lang/python, lang/ruby.
-- This spec merges into neotest's opts (it does NOT call neotest.setup()).
local specs = {}

-- 实时测试：neotest watch（保存/改动时自动重跑，需要 LSP 附加）
table.insert(specs, {
  "nvim-neotest/neotest",
  keys = {
    { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Watch File (实时测试)" },
    { "<leader>tW", function() require("neotest").watch.toggle(vim.fn.getcwd()) end, desc = "Watch Project (实时测试)" },
    { "<leader>tq", function() require("neotest").watch.stop() end, desc = "Stop All Watches" },
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
