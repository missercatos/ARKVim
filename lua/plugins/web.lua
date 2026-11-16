-- 前端语言支持：JS / TS / JSX / TSX / HTML / CSS / Vue / Svelte
--
-- 合并了原来的 javascript.lua / typescript.lua / css.lua / html-lsp.lua，
-- 去掉重复配置和失效的 `ts_ls`（LazyVim 的 typescript extra 已使用 vtsls）。
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
        "html",
        "css",
        "scss",
      })
    end,
  },
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
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
      },
    },
  },
}
