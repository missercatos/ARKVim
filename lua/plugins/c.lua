local enabled = vim.fn.executable("clangd") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "c", "cpp" })
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        if ft == "c" or ft == "cpp" then
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
        c = { "clangtidy" },
        cpp = { "clangtidy" },
      },
      linters = {
        clangtidy = {
          -- 有 compile_commands.json 才跑 clang-tidy（否则没有 include/宏定义，误报会很多）
          condition = function(ctx)
            return vim.fs.find("compile_commands.json", { upward = true, path = ctx.dirname })[1] ~= nil
          end,
          prepend_args = {
            "-p",
            function()
              local f = vim.fs.find("compile_commands.json", {
                upward = true,
                path = vim.fn.expand("%:p:h"),
              })[1]
              return f and vim.fs.dirname(f) or "."
            end,
          },
        },
      },
    },
  },
}
