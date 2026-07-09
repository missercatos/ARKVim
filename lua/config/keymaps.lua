-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap

local function map(mode, lhs, rhs, opts)
  local keys = { noremap = true, silent = true }
  if opts then
    keys = vim.tbl_extend("force", keys, opts)
  end
  keymap.set(mode, lhs, rhs, keys)
end

-- 在浮动终端中编译运行 C++
map("n", "<leader>r", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local output = dir .. "/" .. vim.fn.expand("%:t:r")

  local cmd = string.format('g++ -std=c++17 -Wall -o "%s" "%s" && "%s"', output, file, output)

  Snacks.terminal(cmd, {
    cwd = dir,
    win = {
      position = "float",
      width = 0.9,
      height = 0.8,
    },
    interactive = true,
  })
end, { desc = "在浮动终端中编译运行 C++" })

-- 在下方打开终端（当前文件所在目录）
map("n", "<leader>ft", function()
  local dir = vim.fn.expand("%:p:h")
  Snacks.terminal(nil, {
    cwd = dir,
    win = {
      position = "bottom",
      height = 0.25,
    },
  })
end, { desc = "下方终端" })

-- 终端模式下 Ctrl+HJKL 跳转窗口
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端左移" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端下移" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端上移" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端右移" })
