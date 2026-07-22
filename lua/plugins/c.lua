local enabled = vim.fn.executable("clangd") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "c" })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "c" then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },
}
