return {
  -- molten-nvim: Jupyter inline output
  {
    "benlubas/molten-nvim",
    ft = { "python", "jupyter" },
    build = ":UpdateRemotePlugins",
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<CR>", desc = "Jupyter 初始化" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<CR>", desc = "Run Line" },
      { "<leader>jr", "<cmd>MoltenReevaluateCell<CR>", desc = "Re-evaluate Cell" },
      { "<leader>jo", "<cmd>MoltenOpenInBrowser<CR>", desc = "Open in Browser" },
    },
    config = function()
      vim.g.molten_output_type = "window"
      vim.g.molten_auto_open_output = true
      vim.g.molten_cover_comment_start_end = true
      vim.g.molten_image_provider = "snacks.nvim"
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
    end,
  },

  -- sniprun: inline code execution
  {
    "michaelb/sniprun",
    build = "bash install.sh",
    cmd = { "SnipRun", "SnipReset", "SnipInfo" },
    keys = {
      { "<leader>js", "<cmd>SnipRun<CR>", desc = "Run snippet", mode = { "n", "x" } },
      { "<leader>jc", "<cmd>SnipClose<CR>", desc = "Close output" },
    },
    config = function()
      require("sniprun").setup({
        display = { "TemporaryCodeResult" },
        inline_handlers = {},
      })
    end,
  },
}
