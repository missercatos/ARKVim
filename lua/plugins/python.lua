local enabled = vim.fn.executable("python3") == 1

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "python" })
    end,
  },
  {
    "mason-org/mason.nvim",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "basedpyright",
        "debugpy",
        "ruff",
        "mypy",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
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
  {
    "stevearc/conform.nvim",
    enabled = enabled,
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
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "ruff", "mypy" },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    enabled = enabled,
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      keys = {
        { "<leader>dPt", function() require('dap-python').test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require('dap-python').test_class() end, desc = "Debug Class", ft = "python" },
      },
      config = function()
        require("dap-python").setup("debugpy-adapter")
      end,
    },
    config = function()
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
  {
    "nvim-neotest/neotest",
    enabled = enabled,
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
        },
      },
    },
  },
}
