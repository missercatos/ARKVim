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
map("n", "<leader>to", function()
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  Snacks.terminal("opencode", {
    cwd = root,
    win = {
      position = "right",
      width = 0.22,
    },
    interactive = true,
  })
end, { desc = "在右侧终端中打开 opencode" })

-- 在下方打开单个终端
map("n", "<leader>ftc", function()
  Snacks.terminal(nil, {
    cwd = LazyVim.root(),
    win = {
      position = "bottom",
      height = 0.25,
    },
  })
end, { desc = "下方终端" })

-- 下方左右：终端 + cava
map("n", "<leader>ftv", function()
  local root = LazyVim.root()
  Snacks.terminal(nil, {
    cwd = root,
    win = {
      position = "bottom",
      height = 0.25,
    },
  })
  vim.cmd("vsplit")
  vim.cmd("wincmd l")
  vim.cmd("enew")
  local chan = vim.fn.termopen(vim.o.shell, { cwd = root })
  vim.fn.chansend(chan, "cava\n")
  vim.cmd("stopinsert")
  vim.api.nvim_win_set_width(0, math.floor(vim.api.nvim_win_get_width(0) * 0.8))
  vim.cmd("wincmd h")
end, { desc = "下方终端 + cava" })

-- 在浮动终端中打开 opencode
map("n", "<leader>tO", function()
  Snacks.terminal("opencode", {
    win = {
      position = "float",
      width = 0.9,
      height = 0.8,
    },
    interactive = true,
  })
end, { desc = "在浮动终端中打开 opencode" })

-- 终端模式下 Ctrl+HJKL 跳转窗口
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端左移" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端下移" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端上移" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端右移" })
