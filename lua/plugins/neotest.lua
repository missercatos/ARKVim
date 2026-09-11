-- Extra neotest adapters not covered by LazyVim's lang extras.
-- Go/Python/Ruby adapters already come from LazyVim's lang/go, lang/python, lang/ruby.
-- This spec merges into neotest's opts (it does NOT call neotest.setup()).
local specs = {}

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
