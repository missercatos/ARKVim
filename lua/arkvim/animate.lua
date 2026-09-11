-- arkvim/animate.lua — lightweight window fade-in/fade-out
-- Uses Snacks.animate for smooth, low-overhead transitions.
-- Call M.win(win) to animate a Snacks.win on open/close.

local M = {}

--- Animate a Snacks.win with fade-in on open, fade-out on close.
--- Attach via on_win / on_close in snacks win config.
---@param win snacks.win
---@param opts? {duration?: number, fps?: number}
function M.win(win, opts)
  if not win or not win.win or not vim.api.nvim_win_is_valid(win.win) then
    return
  end
  opts = opts or {}
  local duration = opts.duration or 120 -- ms total
  local fps = opts.fps or 60

  -- Start fully transparent
  pcall(vim.api.nvim_set_option_value, "winblend", 100, { win = win.win })

  -- Fade in: 100 → 0
  Snacks.animate(100, 0, function(val, ctx)
    if not win.win or not vim.api.nvim_win_is_valid(win.win) then
      return
    end
    pcall(vim.api.nvim_set_option_value, "winblend", val, { win = win.win })
  end, { duration = duration, easing = "easeOutCubic", int = true, fps = fps, id = "arkvim_fade_" .. win.win })
end

--- Animate fade-out then close.
---@param win snacks.win
---@param opts? {duration?: number, fps?: number, on_done? : fun()}
function M.win_close(win, opts)
  if not win or not win.win or not vim.api.nvim_win_is_valid(win.win) then
    if opts and opts.on_done then opts.on_done() end
    return
  end
  opts = opts or {}
  local duration = opts.duration or 80
  local fps = opts.fps or 60
  local winnr = win.win

  Snacks.animate(0, 100, function(val, ctx)
    if not vim.api.nvim_win_is_valid(winnr) then
      return
    end
    pcall(vim.api.nvim_set_option_value, "winblend", val, { win = winnr })
    if ctx.done then
      pcall(function()
        if win.close then
          win:close()
        elseif vim.api.nvim_win_is_valid(winnr) then
          vim.api.nvim_win_close(winnr, true)
        end
      end)
      if opts.on_done then opts.on_done() end
    end
  end, { duration = duration, easing = "easeInCubic", int = true, fps = fps, id = "arkvim_fade_" .. winnr })
end

--- Simple fade-in for a raw vim window (not snacks.win).
---@param winnr number
---@param opts? {duration?: number, fps?: number}
function M.raw_win(winnr, opts)
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then return end
  opts = opts or {}
  pcall(vim.api.nvim_set_option_value, "winblend", 100, { win = winnr })
  Snacks.animate(100, 0, function(val)
    if not vim.api.nvim_win_is_valid(winnr) then return end
    pcall(vim.api.nvim_set_option_value, "winblend", val, { win = winnr })
  end, { duration = opts.duration or 120, easing = "easeOutCubic", int = true, fps = opts.fps or 60, id = "arkvim_rawfade_" .. winnr })
end

return M
