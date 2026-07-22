local enabled = vim.fn.executable("ruby") == 1

return {
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        solargraph = {
          settings = {
            solargraph = {
              autoformat = true,
              diagnostics = true,
              completion = true,
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "ruby" })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "ruby" then
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
        ruby = { "rubocop" },
      },
    },
  },
}
