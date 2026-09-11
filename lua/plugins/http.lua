return {
  -- kulala.nvim: HTTP client
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "Send Request", ft = "http" },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "Toggle Headers/Body", ft = "http" },
      { "<leader>Rn", function() require("kulala").jump_next() end, desc = "Next Request", ft = "http" },
      { "<leader>Rp", function() require("kulala").jump_prev() end, desc = "Prev Request", ft = "http" },
      { "<leader>Rb", function() require("kulala").scratchpad() end, desc = "Scratchpad", ft = "http" },
      { "<leader>Rr", function() require("kulala").replay() end, desc = "Replay Last", ft = "http" },
    },
    config = function()
      require("kulala").setup({
        default_view = "body",
        default_headers = {},
        debug = false,
      })
    end,
  },
}
