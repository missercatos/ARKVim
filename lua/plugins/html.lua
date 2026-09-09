-- HTML & CSS editing helpers (emmet expansion + live color preview)
-- Emmet usage (insert/visual mode):
--   write a CSS/Emmet abbreviation and press <C-y>,  (or <C-y> then the emmet action)
--   e.g. `ul>li*5>a[href=#]{Link $}` then <C-y>,
return {
  {
    "mattn/emmet-vim",
    ft = {
      "html", "htmldjango", "css", "scss", "sass", "less",
      "xml", "javascriptreact", "typescriptreact", "vue", "svelte",
    },
    init = function()
      -- expand in insert mode; keep visual/block handling on
      vim.g.user_emmet_mode = "a"
      vim.g.user_emmet_leader_key = "<C-y>"
    end,
  },
  {
    -- live color display for CSS/HTML (hex, rgb/hsl, tailwind)
    "NvChad/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = {
      filetypes = {
        "css", "scss", "sass", "less", "html", "htmldjango",
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "svelte", "python",
      },
      user_default_options = {
        RRGGBB = true, -- #rrggbb
        RRGGBBAA = true, -- #rrggbbaa
        names = false, -- do not colorize "Name" colors
        rgb_fn = true, -- css rgb() / rgba() functions
        hsl_fn = true, -- css hsl() / hsla() functions
        mode = "background", -- paint the color behind the token
        tailwind = true, -- tailwind palette support
      },
    },
  },
}
