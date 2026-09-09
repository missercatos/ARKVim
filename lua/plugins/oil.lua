-- oil.nvim: edit the filesystem like a normal buffer (vim-vinegar style)
-- Tree explorer (<space>e) stays as Snacks explorer; oil is a fast overlay/manager.
return {
  {
    "stevearc/oil.nvim",
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- oil must be available to take over directory buffers (`nvim .`, `:e dir`)
    -- oil.nvim upstream explicitly advises against lazy loading
    lazy = false,
    keys = {
      {
        "<leader>o",
        function()
          require("oil").toggle_float(vim.fn.expand("%:p:h"))
        end,
        desc = "Oil: parent directory",
      },
      {
        "<leader>O",
        function()
          require("oil").toggle_float()
        end,
        desc = "Oil: cwd",
      },
      {
        "-",
        "<CMD>Oil<CR>",
        desc = "Oil: open parent directory",
      },
    },
    opts = {
      -- oil takes over directory buffers (`nvim .`, `:e dir`)
      default_file_explorer = true,
      columns = { "icon" },
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      delete_to_trash = false,
      skip_confirm_for_simple_edits = false,
      prompt_save_on_select_new_entry = true,
      cleanup_delay_ms = 2000,
      lsp_file_methods = {
        enabled = true,
        timeout_ms = 1000,
        autosave_changes = false,
      },
      constrain_cursor = "editable",
      watch_for_changes = false,
      use_default_keymaps = true,
      view_options = {
        show_hidden = false,
        natural_order = "fast",
        case_insensitive = false,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },
      float = {
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = { winblend = 0 },
      },
    },
  },
}
