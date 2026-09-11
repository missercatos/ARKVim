return {
  -- dap core: nvim-dap-ui + virtual-text + mason-dap
  {
    "LazyVim/LazyVim",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        keys = {
          { "<leader>du", function() require("dapui").toggle({}) end, desc = "Debug: toggle UI" },
          { "<leader>de", function() require("dapui").eval() end, desc = "Debug: eval", mode = { "n", "v" } },
        },
        config = function()
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup()
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open({}) end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close({}) end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close({}) end
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        config = true,
      },
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "mason-org/mason.nvim",
        opts = {
          ensure_installed = { "codelldb" },
          handlers = {},
        },
      },
    },
  },

  -- neotest: test runner UI
  {
    "LazyVim/LazyVim",
    dependencies = {
      {
        "nvim-neotest/neotest",
        dependencies = {
          "nvim-neotest/nvim-nio",
          "nvim-treesitter/nvim-treesitter",
          "antoinemadec/FixCursorHold.nvim",
        },
        keys = {
          { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
          { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
          { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest" },
          { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last" },
          { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
          { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
          { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
          { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
        },
        config = function()
          require("neotest").setup({
            adapters = {},
            output = { enabled = true, open_on_run = true },
            summary = { enabled = true },
          })
        end,
      },
    },
  },

  -- refactoring.nvim: IDE-like refactoring
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      { "<leader>rs", function() require("refactoring").refactor("Extract Function") end, desc = "Extract Function", mode = { "n", "x" } },
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, desc = "Inline Variable", mode = { "n", "x" } },
      { "<leader>rp", function() require("refactoring").debug.printf({}) end, desc = "Print Function" },
      { "<leader>rx", function() require("refactoring").refactor("Extract Block") end, desc = "Extract Block", mode = { "n", "x" } },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("refactoring").setup()
    end,
  },

  -- neogen: doc comment generation
  {
    "danymat/neogen",
    cmd = "Neogen",
    keys = {
      { "<leader>cn", function() require("neogen").generate() end, desc = "Generate doc comment" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
  },

  -- diffview: git diff / conflict resolution
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gV", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
      { "<leader>gF", "<cmd>DiffviewFileHistory %<CR>", desc = "File History" },
    },
    config = true,
  },
}
