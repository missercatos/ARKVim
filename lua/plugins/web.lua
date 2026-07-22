local enabled = vim.fn.executable("node") == 1

return {
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        html = {},
        cssls = {},
        tailwindcss = {},
        emmet_language_server = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "html",
        "css",
        "scss",
        "tailwindcss",
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
      },
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        if vim.tbl_contains({ "html", "css", "scss", "less" }, ft) then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },
}
