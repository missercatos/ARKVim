return {
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
