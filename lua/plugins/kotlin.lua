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
