-- arkvim/animate.lua — lightweight window fade-in/fade-out
-- Uses Snacks.animate for smooth, low-overhead transitions.

local M = {}
local Easing = require("snacks.animate.easing")

--- Fade-in a Snacks.win (winblend 100 → 0).
---@param win snacks.win
---@param opts? {duration?: number, fps?: number}
function M.win(win, opts)
  if not win or not win.win or not vim.api.nvim_win_is_valid(win.win) then return end
  opts = opts or {}
  local dur = opts.duration or 120
  local winnr = win.win
  pcall(vim.api.nvim_set_option_value, "winblend", 100, { win = winnr })
  Snacks.animate(100, 0, function(val)
    if not vim.api.nvim_win_is_valid(winnr) then return end
    pcall(vim.api.nvim_set_option_value, "winblend", val, { win = winnr })
  end, { duration = dur, easing = Easing.outCubic, int = true, fps = opts.fps or 60, id = "af_" .. winnr })
end

--- Fade-in for a raw vim window number.
---@param winnr number
---@param opts? {duration?: number, fps?: number}
function M.raw_win(winnr, opts)
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then return end
  opts = opts or {}
  pcall(vim.api.nvim_set_option_value, "winblend", 100, { win = winnr })
  Snacks.animate(100, 0, function(val)
    if not vim.api.nvim_win_is_valid(winnr) then return end
    pcall(vim.api.nvim_set_option_value, "winblend", val, { win = winnr })
  end, { duration = opts.duration or 120, easing = Easing.outCubic, int = true, fps = opts.fps or 60, id = "arf_" .. winnr })
end

return M
