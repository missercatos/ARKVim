-- arkvim/gitgraph.lua — 左侧 Git 提交图谱（vim-flog）
--
-- 说明：serie 是图像 TUI，依赖 kitty/iTerm2 图像协议，且官方明确没有文字回退，
-- 所以不能放在 Neovim 的内嵌终端里（只有提交列表、没有图谱）。
-- 这里用 vim-flog 在 Neovim 内开一个左侧垂直分屏，提供文本版分支/合并图谱；
-- 回车查看 commit（Fugitive），a 切换全部分支，g? 看帮助，gq 关闭。
local M = {}

local function find_flog_win()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].filetype == "floggraph" then
      return w
    end
  end
  return nil
end

local function in_git_repo(start)
  vim.fn.systemlist({ "git", "-C", start, "rev-parse", "--show-toplevel" })
  return vim.v.shell_error == 0
end

--- 开关左侧 Git 图谱
function M.toggle()
  local existing = find_flog_win()
  if existing then
    vim.api.nvim_win_close(existing, true)
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  local start = (file ~= "" and file:sub(1, 1) == "/")
      and vim.fn.fnamemodify(file, ":h")
    or vim.fn.getcwd()

  if not in_git_repo(start) and not in_git_repo(vim.fn.getcwd()) then
    vim.notify("当前文件不在 git 仓库中", vim.log.levels.WARN, { title = "ARKVIM · git graph" })
    return
  end

  -- 确保 vim-flog 已加载（它是 lazy 插件，Flogsplit 是 lazy command）
  pcall(function()
    require("lazy").load({ plugins = { "vim-flog" } })
  end)

  -- topleft + vertical：左侧垂直分屏；-all 显示所有分支；-auto-update 自动刷新
  vim.cmd("topleft vertical Flogsplit -all -auto-update")

  local win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * 0.35)
  width = math.max(30, math.min(width, vim.o.columns - 10))
  vim.api.nvim_win_set_width(win, width)
  vim.wo[win].winfixwidth = true
end

function M.setup()
  vim.keymap.set("n", "<leader>gE", M.toggle, { desc = "Git 图谱 (左侧)", silent = true, noremap = true })
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>gE", desc = "Git 图谱 (左侧)" } })
  end
end

return M
