local enabled = vim.fn.executable("dart") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "dart" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        dartls = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "dart" then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },
}
