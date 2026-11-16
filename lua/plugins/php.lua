local enabled = vim.fn.executable("php") == 1

return {
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        phpactor = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        php = { "php-cs-fixer" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        php = { "phpcs" },
      },
    },
  },
}
