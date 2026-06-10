return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "python" })
    end,
  },

  -- Mason: install Python tools
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "basedpyright",
        "debugpy",
        "ruff",
        "mypy",
      })
    end,
  },

  -- LSP: basedpyright
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
              },
            },
          },
        },
      },
    },
  },

  -- Conform: format with ruff on save
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
      },
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "python" then
          return { timeout_ms = 5000, lsp_fallback = true }
        end
      end,
    },
  },

  -- nvim-lint
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "ruff", "mypy" },
      },
    },
  },

  -- DAP: debugpy
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.configurations.python = {
        {
          name = "Launch file",
          type = "debugpy",
          request = "launch",
          program = "${file}",
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
        },
        {
          name = "Launch module",
          type = "debugpy",
          request = "launch",
          module = function()
            return vim.fn.input("Module: ", "", "file")
          end,
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
        },
        {
          name = "Attach",
          type = "debugpy",
          request = "attach",
          connect = {
            host = "localhost",
            port = 5678,
          },
        },
      }
    end,
  },
}
