return {
  -- 配置 LazyVim 禁用冲突的 extras
  {
    "LazyVim/LazyVim",
    opts = {
      extras = {
        ["ui.alpha"] = false,  -- 禁用默认的 alpha 配置，使用下面的自定义配置
        ["editor.snacks_picker"] = false,  -- 禁用 snacks_picker 对 alpha 的修改
      },
    },
  },
  
  -- tokyonight 主题配置
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  
  -- alpha-nvim 启动界面配置
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local logo = [[
   █████╗ ██████╗ ██╗  ██╗██╗   ██╗██╗███╗   ███╗
  ██╔══██╗██╔══██╗██║ ██╔╝██║   ██║██║████╗ ████║
  ███████║██████╔╝█████╔╝ ██║   ██║██║██╔████╔██║
  ██╔══██║██╔══██╗██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
  ██║  ██║██║  ██║██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
      ]]
      dashboard.section.header.val = vim.split(logo, "\n")
      -- stylua: ignore
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file",       "<cmd> lua LazyVim.pick()() <cr>"),
        dashboard.button("n", " " .. " New file",        [[<cmd> ene <BAR> startinsert <cr>]]),
        dashboard.button("r", " " .. " Recent files",    [[<cmd> lua LazyVim.pick("oldfiles")() <cr>]]),
        dashboard.button("g", " " .. " Find text",       [[<cmd> lua LazyVim.pick("live_grep")() <cr>]]),
        dashboard.button("c", " " .. " Config",          "<cmd> lua LazyVim.pick.config_files()() <cr>"),
        dashboard.button("s", " " .. " Restore Session", [[<cmd> lua require("persistence").load() <cr>]]),
        dashboard.button("x", " " .. " Lazy Extras",     "<cmd> LazyExtras <cr>"),
        dashboard.button("l", "◆ " .. " ark",            "<cmd> Lazy <cr>"),
        dashboard.button("q", " " .. " Quit",            "<cmd> qa <cr>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      -- dashboard.section.header.opts.hl = "AlphaHeader"  -- 不使用单一颜色，使用多色
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 8
      return dashboard
    end,
    config = function(_, dashboard)
      -- 设置按钮和页脚颜色（保持不变）
        vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#9ece6a" })
        vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#7aa2f7" })
        vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = "#bb9af7" })
      
       -- Tokyo-night 柔和颜色（适配主题色）
       local tokyo_colors = {
         "#7aa2f7", -- 柔和蓝色 (ark)
         "#7aa2f7", -- 柔和蓝色 (ark)
         "#7aa2f7", -- 柔和蓝色 (ark)
         "#9ece6a", -- 柔和绿色 (vim)
         "#9ece6a", -- 柔和绿色 (vim)
         "#9ece6a", -- 柔和绿色 (vim)
       }
      
      -- 为每行艺术字创建不同的高亮组
      for i, color in ipairs(tokyo_colors) do
        vim.api.nvim_set_hl(0, "AlphaHeader" .. i, { fg = color })
      end
      
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          once = true,
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      require("alpha").setup(dashboard.opts)

      -- 在Alpha准备好后为每行艺术字设置不同颜色
      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "AlphaReady",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          
          -- 找到艺术字行（通常在最前面）
          local art_start_line = 0
          for i, line in ipairs(lines) do
            if line:match("█████") then
              art_start_line = i - 1  -- 转换为0-indexed
              break
            end
          end
          
          -- 为每行艺术字设置高亮
          if art_start_line >= 0 then
            for i = 1, 6 do
              if art_start_line + i - 1 < #lines then
                vim.api.nvim_buf_add_highlight(
                  buf,
                  -1,  -- namespace id, -1表示匿名
                  "AlphaHeader" .. i,
                  art_start_line + i - 1,
                  0,   -- 起始列
                  -1   -- 结束列（-1表示整行）
                )
              end
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "LazyVimStarted",
        callback = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          dashboard.section.footer.val = "⚡ Neovim loaded "
            .. stats.loaded
            .. "/"
            .. stats.count
            .. " plugins in "
            .. ms
            .. "ms"
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },
}