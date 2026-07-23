local enabled = vim.fn.executable("rustc") == 1

return {
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
      },
    },
  },
}
