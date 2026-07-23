local enabled = vim.fn.executable("go") == 1

return {
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "go" then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
    },
  },
}
