-- hinell/duplicate.nvim: duplicate lines / visual selections / text-objects
-- Docs: https://github.com/hinell/duplicate.nvim
--
--   <leader>yd  duplicate line below  (normal)  / duplicate selection (visual)
--   <leader>yD  duplicate line above  (normal)  / duplicate selection (visual)
return {
  {
    "hinell/duplicate.nvim",
    keys = {
      {
        "<leader>yd",
        "<Cmd>LineDuplicate +1<CR>",
        mode = "n",
        desc = "Duplicate line below",
      },
      {
        "<leader>yD",
        "<Cmd>LineDuplicate -1<CR>",
        mode = "n",
        desc = "Duplicate line above",
      },
      {
        "<leader>yd",
        "<Cmd>VisualDuplicate +1<CR>",
        mode = "x",
        desc = "Duplicate selection below",
      },
      {
        "<leader>yD",
        "<Cmd>VisualDuplicate -1<CR>",
        mode = "x",
        desc = "Duplicate selection above",
      },
    },
    config = function()
      -- options are read by the plugin's own config module when it loads
      vim.g["duplicate-nvim-config"] = vim.tbl_deep_extend("force", vim.g["duplicate-nvim-config"] or {}, {
        visual = {
          selectAfter = true, -- select the duplicated text after inserting
          block = true, -- support line-wise / block visual duplication
        },
      })
    end,
  },
}
