-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- -- 文件：~/.config/nvim/lua/config/keymaps.lua
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

-- 在右侧终端中打开 opencode
map("n", "<leader>ao", function()
  Snacks.terminal("opencode", {
    win = {
      position = "right",
      width = 0.3,
    },
    interactive = true,
  })
end, { desc = "在右侧终端中打开 opencode" })

-- 在浮动终端中打开 opencode
map("n", "<leader>aO", function()
  Snacks.terminal("opencode", {
    win = {
      position = "float",
      width = 0.9,
      height = 0.8,
    },
    interactive = true,
  })
end, { desc = "在浮动终端中打开 opencode" })
