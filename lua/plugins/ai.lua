return {
  -- sidekick: AI agent integration (Claude Code, etc.)
  {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    keys = {
      { "<leader>As", function() require("sidekick").toggle() end, desc = "Sidekick Toggle" },
      { "<leader>Aa", function() require("sidekick").ask() end, desc = "Sidekick Ask" },
    },
    dependencies = { "folke/snacks.nvim" },
    config = true,
  },

  -- copilot: GitHub Copilot (optional, needs auth)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },
      suggestion = { enabled = false },
      filetypes = { markdown = true, help = true },
    },
  },
}
