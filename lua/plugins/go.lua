local enabled = vim.fn.executable("go") == 1

-- Go 工具链改用系统/ user-local 版本：
--   gopls: 系统包
--   goimports / gofumpt / dlv: go install 到 ~/.local/bin
-- 不再让 Mason 反复尝试安装这些工具（失败时会在启动/保存时弹错误通知）。
local MASON_SKIP = {
  gopls = true,
  goimports = true,
  gofumpt = true,
  delve = true,
  gomodifytags = true,
  impl = true,
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = { mason = false },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(p)
        return not MASON_SKIP[p]
      end, opts.ensure_installed or {})
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.automatic_installation = { exclude = { "delve" } }
      opts.ensure_installed = vim.tbl_filter(function(p)
        return p ~= "delve"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
      linters = {
        golangcilint = {
          ignore_exitcode = true,
        },
      },
    },
  },
}
