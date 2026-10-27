local enabled = vim.fn.executable("rustc") == 1

return {
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        rust = { "clippy" },
      },
      linters = {
        clippy = {
          ignore_exitcode = true,
          condition = function(ctx)
            return vim.fs.find("Cargo.toml", { upward = true, path = ctx.dirname })[1] ~= nil
          end,
          args = {
            "clippy",
            "--message-format=json",
            "--manifest-path",
            function()
              local root = vim.fs.root(0, "Cargo.toml")
              return root and (root .. "/Cargo.toml") or "Cargo.toml"
            end,
          },
        },
      },
    },
  },
}
