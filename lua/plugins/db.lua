return {
  -- vim-dadbod: database client
  {
    "tpope/vim-dadbod",
    cmd = { "DB", "DBUI", "DBUIToggle", "DBFindConnection", "DBNewConnection" },
  },

  -- dadbod-ui: database browser
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle" },
    keys = {
      { "<leader>Xd", "<cmd>DBUIToggle<CR>", desc = "数据库面板" },
      -- 注意：不要用 <leader>Ds/<leader>Dl，那是 Docker 分组
      { "<leader>Xds", "<cmd>DB save<CR>", desc = "保存连接", mode = { "n", "v" } },
      { "<leader>Xdl", "<cmd>DB last<CR>", desc = "最近连接" },
    },
    init = function()
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_win_position = "right"
      vim.g.db_ui_win_width = 40
      vim.g.db_ui_auto_execute_table_selector = true
    end,
    dependencies = { "tpope/vim-dadbod" },
  },
}
