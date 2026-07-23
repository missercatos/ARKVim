local enabled = vim.fn.executable("node") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "javascript",
        "typescript",
        "tsx",
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
      },
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        if vim.tbl_contains({ "javascript", "typescript", "javascriptreact", "typescriptreact" }, ft) then
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
        javascript = { "eslint" },
        typescript = { "eslint" },
        javascriptreact = { "eslint" },
        typescriptreact = { "eslint" },
      },
    },
  },
}
