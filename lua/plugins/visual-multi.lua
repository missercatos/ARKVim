-- mg979/vim-visual-multi: multiple cursors / multiple selections
-- Start: select a word then keep pressing <C-n> to add the next match;
-- or press <C-n> on an empty visual. `q` skips, `Q` removes a region.
-- Docs: https://github.com/mg979/vim-visual-multi
return {
  {
    "mg979/vim-visual-multi",
    event = { "VeryLazy" },
    init = function()
      -- use the plugin defaults, but keep mouse handling native
      vim.g.VM_default_mappings = 1
      vim.g.VM_mouse_mappings = 0
      vim.g.VM_set_statusline = 0
      vim.g.VM_silent_exit = 1
    end,
  },
}
