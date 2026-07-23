local enabled = vim.fn.executable("ruby") == 1

return {
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        ruby = { "rubocop" },
      },
    },
  },
}
