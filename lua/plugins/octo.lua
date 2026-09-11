return {
  -- octo.nvim: GitHub PR/issue review
  {
    "pwntester/octo.nvim",
    cmd = { "Octo" },
    keys = {
      { "<leader>GP", "<cmd>Octo pr list<CR>", desc = "List PRs" },
      { "<leader>GI", "<cmd>Octo issue list<CR>", desc = "List Issues" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup({
        picker = "snacks",
        default_to_projects_v2 = true,
      })
    end,
  },
}
