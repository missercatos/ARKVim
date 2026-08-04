-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.env.DISPLAY == nil and vim.env.WAYLAND_DISPLAY == nil then
  vim.o.termguicolors = false
end

-- 战术终端（foot/alacritty）：准星光标拖影 + 快速响应 + 原生极简 UI
if vim.g.tactical then
  -- 光标拖影：cursorline(行) + cursorcolumn(列) 十字准星，配绿底高亮
  vim.opt.cursorcolumn = true
  -- 原生每窗状态栏（替代 lualine 图标条）
  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('arkvim.tactical').stl()"
  -- 显眼块状光标
  vim.opt.guicursor = "n-v-c-i:block"
  -- bufferline 关闭后的缓冲区切换补位
  vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Prev Buffer" })
  vim.keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Next Buffer" })

  -- LazyVim 的 options 在插件 setup 时执行（晚于此文件），这里在 VimEnter 兜底覆盖
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.opt.smoothscroll = false -- 关平滑滚动，指哪打哪
      vim.opt.timeoutlen = 150 -- 前缀键快速响应
      vim.opt.updatetime = 100 -- 光标相关刷新更跟手
      vim.opt.redrawtime = 200 -- 大文件快速重绘
      vim.opt.matchtime = 3 -- 配对括号即时跳转
      vim.opt.lazyredraw = false -- 强制即时重绘
      vim.opt.scrolloff = 3
      vim.opt.cursorcolumn = true -- 十字准星（启动流程中可能被恢复逻辑覆盖）
      vim.opt.laststatus = 2
      vim.opt.winbar = "" -- 去 winbar 装饰
      vim.opt.guicursor = "n-v-c-i:block"
      -- 应用战术科学配色（覆盖晚于 colorscheme 应用的任何高亮）
      require("arkvim.tactical").apply()
    end,
  })
end
