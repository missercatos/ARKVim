-- 工具可用性过滤：本机没装的 linter/formatter 不再在保存时弹通知。
--
-- 具体实现在 arkvim/lint.lua 和 arkvim/format.lua；它们在 VeryLazy 后运行，
-- 此时 LazyVim/语言插件的 linters_by_ft、formatters_by_ft 已经合并完成。
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("arkvim.lint").filter_missing()
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("arkvim.format").filter_missing()
        end,
      })
    end,
  },
}
