-- ArkVim Theme Switcher
-- Uses terminal section to display colored ANSI character art

local hrtime = vim.uv and vim.uv.hrtime or vim.loop.hrtime
math.randomseed(hrtime())

local M = {}

M.themes = {
  amya = {
    name = "amya",
    art_file = vim.fn.stdpath("config") .. "/art_amya.txt",
    logo_text = "ⒶⓇⓀ Ⓥⓘⓜ",
    logo_color = "#e8b878",
    colors = {
      bg = "#1a1028", bg_dark = "#1e152e", bg_float = "#1e1530",
      bg_highlight = "#2a1f3d", bg_popup = "#1e1530", bg_search = "#2a2040",
      bg_sidebar = "NONE", bg_statusline = "#1e152e", bg_visual = "#2d2240",
      fg = "#d8cce0", fg_dark = "#9a8daa", fg_float = "#e0d5e8",
      fg_gutter = "#4a3d5a", fg_sidebar = "#c0b0d0",
      border = "#3a2d50",
      comment = "#7a6d8a",
      dark3 = "#3a2d50", dark5 = "#2a1f3d",
      blue = "#9a8df0", blue1 = "#b0a0f8", blue2 = "#7a6de0",
      blue5 = "#9a8df0", blue6 = "#6a5dd0", blue7 = "#c0b0f8",
      cyan = "#4fc3f7",
      green = "#a5d6a2", green1 = "#b8e0b5", green2 = "#88c088",
      teal = "#4db6ac",
      magenta = "#d0a0e8", magenta2 = "#e0b8f5",
      orange = "#e8b878", purple = "#c0a0e8",
      red = "#f07880", red1 = "#ff8e96",
      yellow = "#e8d070",
      git = { change = "#e8b878", add = "#a5d6a2", delete = "#f07880" },
      gitSigns = { change = "#e8b878", add = "#b8e0b5", delete = "#ff8e96" },
      diff = { add = "#1a2a18", change = "#2a2418", delete = "#2a1518", text = "#1e1530" },
    },
  },
  amyaa = {
    name = "amyaa",
    art_file = vim.fn.stdpath("config") .. "/art_amyaa.txt",
    logo_text = "ⒶⓇⓀ Ⓥⓘⓜ",
    logo_color = "#70a8f0",
    colors = {
      bg = "#0a1828", bg_dark = "#0f1f38", bg_float = "#101e30",
      bg_highlight = "#182a40", bg_popup = "#101e30", bg_search = "#1a2a40",
      bg_sidebar = "NONE", bg_statusline = "#0f1f38", bg_visual = "#1e2e44",
      fg = "#d0c8c0", fg_dark = "#9098a8", fg_float = "#d8d0c8",
      fg_gutter = "#3a4a60", fg_sidebar = "#b0c0d0",
      border = "#2a3c55",
      comment = "#6a7a90",
      dark3 = "#2a3c55", dark5 = "#1e2e44",
      blue = "#70a8f0", blue1 = "#88b8f8", blue2 = "#5890e0",
      blue5 = "#70a8f0", blue6 = "#4878c8", blue7 = "#a0c8f8",
      cyan = "#4fc3f7",
      green = "#7ec994", green1 = "#90d8a2", green2 = "#60b070",
      teal = "#4db6ac",
      magenta = "#80c8e8", magenta2 = "#a0d8f5",
      orange = "#c8a070", purple = "#80a8d0",
      red = "#f07078", red1 = "#ff8e96",
      yellow = "#d0c070",
      git = { change = "#c8a070", add = "#7ec994", delete = "#f07078" },
      gitSigns = { change = "#c8a070", add = "#90d8a2", delete = "#ff8e96" },
      diff = { add = "#182a18", change = "#2a2418", delete = "#2a1518", text = "#101e30" },
    },
  },
  kastic = {
    name = "kastic",
    art_file = vim.fn.stdpath("config") .. "/art_kastic.txt",
    logo_text = "ⒶⓇⓀ Ⓥⓘⓜ",
    logo_color = "#d0a868",
    colors = {
      bg = "#151515", bg_dark = "#1a1a1a", bg_float = "#1e1e20",
      bg_highlight = "#252530", bg_popup = "#1e1e20", bg_search = "#282830",
      bg_sidebar = "NONE", bg_statusline = "#1a1a1a", bg_visual = "#282835",
      fg = "#d0d0d0", fg_dark = "#909090", fg_float = "#d8d8d8",
      fg_gutter = "#484848", fg_sidebar = "#c0c0c0",
      border = "#3a3a3a",
      comment = "#787878",
      dark3 = "#3a3a3a", dark5 = "#282828",
      blue = "#78a0d8", blue1 = "#90b0e8", blue2 = "#6090c8",
      blue5 = "#78a0d8", blue6 = "#5080b8", blue7 = "#a8c0e8",
      cyan = "#4fc3f7",
      green = "#8cc088", green1 = "#a0d09a", green2 = "#70b068",
      teal = "#4db6ac",
      magenta = "#a890c0", magenta2 = "#c0a8d8",
      orange = "#d0a868", purple = "#9880b0",
      red = "#e87078", red1 = "#f08e96",
      yellow = "#d8c870",
      git = { change = "#d0a868", add = "#8cc088", delete = "#e87078" },
      gitSigns = { change = "#d0a868", add = "#a0d09a", delete = "#f08e96" },
      diff = { add = "#1a2818", change = "#2a2418", delete = "#2a1518", text = "#1e1e20" },
    },
  },
  mon = {
    name = "mon",
    art_file = vim.fn.stdpath("config") .. "/art_mon.txt",
    logo_text = "ⒶⓇⓀ Ⓥⓘⓜ",
    logo_color = "#80c890",
    colors = {
      bg = "#0a1a0f", bg_dark = "#0f1f14", bg_float = "#101e14",
      bg_highlight = "#1a2a1e", bg_popup = "#101e14", bg_search = "#1a2a18",
      bg_sidebar = "NONE", bg_statusline = "#0f1f14", bg_visual = "#1e2e20",
      fg = "#c8d4c8", fg_dark = "#8a9a8a", fg_float = "#d0dcd0",
      fg_gutter = "#3a4a38", fg_sidebar = "#b0c0b0",
      border = "#2a3c28",
      comment = "#6a7a68",
      dark3 = "#2a3c28", dark5 = "#1e2e1e",
      blue = "#60a880", blue1 = "#78b898", blue2 = "#489068",
      blue5 = "#60a880", blue6 = "#388058", blue7 = "#88c8a8",
      cyan = "#4db6ac",
      green = "#80c890", green1 = "#98d8a2", green2 = "#68b078",
      teal = "#4db6ac",
      magenta = "#70b880", magenta2 = "#88c898",
      orange = "#a8c878", purple = "#60a070",
      red = "#e87870", red1 = "#f09088",
      yellow = "#c8d878",
      git = { change = "#a8c878", add = "#80c890", delete = "#e87870" },
      gitSigns = { change = "#a8c878", add = "#98d8a2", delete = "#f09088" },
      diff = { add = "#1a2818", change = "#2a2818", delete = "#2a1518", text = "#101e14" },
    },
  },
}

local hrtime = vim.uv and vim.uv.hrtime or vim.loop.hrtime
math.randomseed(hrtime())
for _ = 1, 4 do math.random() end

local names = vim.tbl_keys(M.themes)
M.current = names[math.random(#names)]
vim.g.arkvim_colors = vim.deepcopy(M.themes[M.current].colors)
vim.fn.system({ "ln", "-sf", M.themes[M.current].art_file, vim.fn.stdpath("config") .. "/art_current.txt" })
vim.fn.writefile({ M.themes[M.current].logo_color }, vim.fn.stdpath("config") .. "/logo_color.txt")

function M.switch(name)
  local t = M.themes[name]
  if not t then
    vim.notify("Theme not found: " .. name, vim.log.levels.ERROR)
    return
  end
  M.current = name
  vim.g.arkvim_colors = vim.deepcopy(t.colors)
  vim.fn.system({ "ln", "-sf", t.art_file, vim.fn.stdpath("config") .. "/art_current.txt" })
  vim.fn.writefile({ t.logo_color }, vim.fn.stdpath("config") .. "/logo_color.txt")

  pcall(vim.cmd, "colorscheme tokyonight")

  pcall(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
      if ok_ft and ft == "snacks_dashboard" then
        -- Force terminal re-render by closing and reopening
        vim.api.nvim_win_close(win, true)
        vim.schedule(function()
          pcall(function()
            require("snacks").dashboard.open()
          end)
        end)
      end
    end
  end)

  vim.notify("Theme: " .. name, vim.log.levels.INFO)
end

function M.next()
  local n = vim.tbl_keys(M.themes)
  table.sort(n)
  for i, v in ipairs(n) do
    if v == M.current then
      M.switch(n[i % #n + 1])
      return
    end
  end
  M.switch(n[1])
end

function M.prev()
  local n = vim.tbl_keys(M.themes)
  table.sort(n)
  for i, v in ipairs(n) do
    if v == M.current then
      M.switch(n[(i - 2) % #n + 1])
      return
    end
  end
  M.switch(n[#n])
end

return M
