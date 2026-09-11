return {
  {
    "stevearc/aerial.nvim",
    event = "LazyFile",
    dependencies = { "nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = function()
      local icons = {}
      pcall(function()
        icons = vim.deepcopy(require("lazyvim.config").icons.kinds)
      end)

      return {
        attach_mode = "global",
        backends = { "lsp", "treesitter", "markdown", "man" },
        show_guides = true,
        layout = {
          resize_to_content = false,
          win_opts = {
            winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
            signcolumn = "yes",
            statuscolumn = " ",
          },
        },
        icons = icons,
        guides = {
          mid_item   = "├╴",
          last_item  = "└╴",
          nested_top = "│ ",
          whitespace = "  ",
        },
      }
    end,
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "符号面板" },
    },
  },
}
