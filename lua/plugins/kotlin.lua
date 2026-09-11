local enabled = vim.fn.executable("kotlin") == 1 or vim.fn.executable("kotlinc") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "kotlin" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        kotlin_language_server = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        kotlin = { "ktlint" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "kotlin" then
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
        kotlin = { "ktlint" },
      },
    },
  },
}
