-- arkvim/bracket_cursor.lua — 匹配括号上的「第二光标」
--
-- 需求：
--   光标停在括号上时，与之配对的另一个括号也用「光标块」覆盖，像 VSCode /
--   IntelliJ 那样一眼可见；但不移动真实光标，离开括号或无配对时立即消失。
--
-- 做法：
--   CursorMoved / CursorMovedI 时用 searchpairpos() 找到配对，用 extmark
--   覆盖那个字符。extmark 优先级高于 rainbow-delimiters / treesitter，
--   所以不会被彩虹括号本身的颜色盖住。高亮组链接到 Cursor，颜色与真实
--   光标一致（随配色方案自动变化）。

local M = {}

local NS = vim.api.nvim_create_namespace("arkvim_bracket_cursor")
local HL = "ArkMatchBracket"

-- 参与配对的括号；方向由光标处字符是否为左括号决定
local PAIRS = {
  ["("] = { open = "(", close = ")" },
  [")"] = { open = "(", close = ")" },
  ["["] = { open = "[", close = "]" },
  ["]"] = { open = "[", close = "]" },
  ["{"] = { open = "{", close = "}" },
  ["}"] = { open = "{", close = "}" },
}

local function set_hl()
  -- 链接到 Cursor：颜色/反显与真实光标完全一致，配色切换时自动跟随
  vim.api.nvim_set_hl(0, HL, { link = "Cursor" })
end

--- 是否位于字符串/注释里（用 treesitter 判断；没有 parser 时不阻止）
---@param row integer 0-based
---@param col integer 0-based
local function in_string_or_comment(row, col)
  local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, row, col)
  if not ok or type(captures) ~= "table" then
    return false
  end
  for _, capture in ipairs(captures) do
    local name = capture.capture or ""
    if name:match("^string") or name:match("^comment") or name:match("^character") then
      return true
    end
  end
  return false
end

local function clear(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  end
end

local function update()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  clear(buf)

  -- 终端、prompt、quickfix 等 buffer 不处理
  if vim.bo[buf].buftype ~= "" then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(col + 1, col + 1)
  local pair = PAIRS[char]
  if not pair then
    return
  end

  -- 字符串/注释里的括号不当作代码括号
  if in_string_or_comment(row, col) then
    return
  end

  -- 光标在左括号上向后找，在右括号上向前找；\V 让括号按字面匹配
  local flags = (char == pair.open) and "nW" or "bnW"
  local found = vim.fn.searchpairpos("\\V" .. pair.open, "", "\\V" .. pair.close, flags, "", 0, 100)
  if found[1] <= 0 then
    return
  end

  local mrow, mcol = found[1] - 1, found[2] - 1
  if mrow == row and mcol == col then
    return
  end

  vim.api.nvim_buf_set_extmark(buf, NS, mrow, mcol, {
    end_col = mcol + 1,
    hl_group = HL,
    priority = 1000, -- 盖住 rainbow-delimiters 的 extmark
  })
end

-- 合并同一轮事件里的多次 CursorMoved，避免重复计算
local pending = false
local function schedule_update()
  if pending then
    return
  end
  pending = true
  vim.schedule(function()
    pending = false
    update()
  end)
end

function M.setup()
  set_hl()

  local grp = vim.api.nvim_create_augroup("arkvim_bracket_cursor", { clear = true })

  vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "TextChanged",
    "TextChangedI",
    "WinEnter",
    "BufEnter",
  }, {
    group = grp,
    callback = schedule_update,
  })

  -- 离开窗口/缓冲区时立即清掉，避免在非活动窗口残留一个「假光标」
  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = grp,
    callback = function()
      clear(vim.api.nvim_get_current_buf())
    end,
  })

  -- 配色方案切换后重新链接高亮组
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = set_hl,
  })
end

return M
