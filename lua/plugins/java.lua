local enabled = vim.fn.executable("java") == 1

return {
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        jdtls = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "java" })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        java = { "google-java-format" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "java" then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },
}
