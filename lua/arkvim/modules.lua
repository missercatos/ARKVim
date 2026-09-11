-- arkvim/modules.lua — multi-module workspace detection & picker
-- Detects workspace roots (npm/pnpm/yarn, Cargo, Go, Maven, Gradle, CMake, Nx, Turborepo, .sln)
-- Lists modules in a Snacks picker; select to cd + detect project.

local M = {}

-- ---------------------------------------------------------------------------
-- workspace detection
-- ---------------------------------------------------------------------------

local MARKERS = {
  -- JavaScript/TypeScript
  { file = "pnpm-workspace.yaml", kind = "pnpm" },
  { file = "lerna.json",          kind = "lerna" },
  { file = "nx.json",             kind = "nx" },
  { file = "turbo.json",          kind = "turbo" },
  { file = "rush.json",           kind = "rush" },
  -- Rust
  { file = "Cargo.toml",          kind = "cargo", check = function(root)
    local f = io.open(root .. "/Cargo.toml", "r")
    if not f then return false end
    local c = f:read("*a"); f:close()
    return c:find("%[workspace%]") ~= nil
  end},
  -- Go
  { file = "go.work",             kind = "gowork" },
  -- Java
  { file = "settings.gradle.kts", kind = "gradle_ws" },
  { file = "settings.gradle",     kind = "gradle_ws" },
  { file = "pom.xml",             kind = "maven_ws", check = function(root)
    local f = io.open(root .. "/pom.xml", "r")
    if not f then return false end
    local c = f:read("*a"); f:close()
    return c:find("<modules>") ~= nil
  end},
  -- .NET
  { file = "*.sln",               kind = "dotnet", glob = true },
}

--- Parse workspace to find sub-modules
local function parse_modules(root, kind)
  local modules = {}

  if kind == "pnpm" or kind == "lerna" or kind == "nx" or kind == "turbo" or kind == "rush" then
    -- read package.json workspaces
    local f = io.open(root .. "/package.json", "r")
    if f then
      local c = f:read("*a"); f:close()
      local ok, pkg = pcall(vim.fn.json_decode, c)
      if ok then
        local ws = pkg.workspaces or (pkg.pnpm and pkg.pnpm.workspaces) or {}
        for _, pattern in ipairs(ws) do
          -- expand glob pattern
          local expanded = vim.fn.glob(root .. "/" .. pattern, false, true)
          for _, d in ipairs(expanded) do
            if vim.fn.isdirectory(d) == 1 then
              local name = vim.fn.fnamemodify(d, ":t")
              modules[#modules + 1] = { name = name, path = d, kind = kind }
            end
          end
        end
      end
    end
  elseif kind == "cargo" then
    local f = io.open(root .. "/Cargo.toml", "r")
    if f then
      local c = f:read("*a"); f:close()
      for member in c:gmatch("members%s*=%s*{([^}]+)}") do
        for path in member:gmatch('"([^"]+)"') do
          local full = root .. "/" .. path
          if vim.fn.isdirectory(full) == 1 then
            local name = vim.fn.fnamemodify(full, ":t")
            modules[#modules + 1] = { name = name, path = full, kind = "rust" }
          end
        end
      end
    end
  elseif kind == "gowork" then
    local f = io.open(root .. "/go.work", "r")
    if f then
      local c = f:read("*a"); f:close()
      for use in c:gmatch("use%s+([^\n]+)") do
        local path = use:match("^%s*(.-)%s*$"):gsub('"', "")
        local full = root .. "/" .. path
        if vim.fn.isdirectory(full) == 1 then
          local name = vim.fn.fnamemodify(full, ":t")
          modules[#modules + 1] = { name = name, path = full, kind = "go" }
        end
      end
    end
  elseif kind == "gradle_ws" then
    local f = io.open(root .. "/settings.gradle" .. (vim.fn.filereadable(root .. "/settings.gradle.kts") == 1 and ".kts" or ""), "r")
    if f then
      local c = f:read("*a"); f:close()
      for inc in c:gmatch("include%s*%(([^)]+)%)") do
        for mod in inc:gmatch('"([^"]+)"') do
          local path = mod:gsub(":", "/"):gsub("^/", "")
          local full = root .. "/" .. path
          if vim.fn.isdirectory(full) == 1 then
            local name = vim.fn.fnamemodify(full, ":t")
            modules[#modules + 1] = { name = name, path = full, kind = "java" }
          end
        end
      end
    end
  elseif kind == "maven_ws" then
    local f = io.open(root .. "/pom.xml", "r")
    if f then
      local c = f:read("*a"); f:close()
      for mod in c:gmatch("<module>([^<]+)</module>") do
        local full = root .. "/" .. mod
        if vim.fn.isdirectory(full) == 1 then
          local name = vim.fn.fnamemodify(full, ":t")
          modules[#modules + 1] = { name = name, path = full, kind = "java" }
        end
      end
    end
  elseif kind == "dotnet" then
    local sln = vim.fn.glob(root .. "/*.sln", false, true)[1]
    if sln then
      local f = io.open(sln, "r")
      if f then
        local c = f:read("*a"); f:close()
        for proj_path in c:gmatch('Project%([^"]+%)%s*=%s*"([^"]+)"') do
          local full = root .. "/" .. proj_path
          if vim.fn.filereadable(full) == 1 then
            local name = vim.fn.fnamemodify(full, ":t:r")
            modules[#modules + 1] = { name = name, path = vim.fn.fnamemodify(full, ":h"), kind = "csharp" }
          end
        end
      end
    end
  end

  -- fallback: if no modules found, use root itself
  if #modules == 0 then
    modules[#modules + 1] = { name = vim.fn.fnamemodify(root, ":t"), path = root, kind = kind }
  end

  return modules
end

--- Find workspace root from current file/cwd
local function find_workspace()
  local file = vim.fn.expand("%:p")
  local start = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local dir = start

  for _ = 1, 20 do
    for _, m in ipairs(MARKERS) do
      if m.glob then
        local matches = vim.fn.glob(dir .. "/" .. m.file, false, true)
        if #matches > 0 then
          return dir, m.kind
        end
      else
        if vim.fn.filereadable(dir .. "/" .. m.file) == 1 then
          if m.check then
            if m.check(dir) then return dir, m.kind end
          else
            return dir, m.kind
          end
        end
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil, nil
end

-- ---------------------------------------------------------------------------
-- picker
-- ---------------------------------------------------------------------------

local function detect_lang_for_path(path)
  if vim.fn.filereadable(path .. "/Cargo.toml") == 1 then return "Rust" end
  if vim.fn.filereadable(path .. "/go.mod") == 1 then return "Go" end
  if vim.fn.filereadable(path .. "/package.json") == 1 then return "Node" end
  if vim.fn.filereadable(path .. "/pom.xml") == 1 then return "Java" end
  if vim.fn.filereadable(path .. "/CMakeLists.txt") == 1 then return "C/C++" end
  if vim.fn.filereadable(path .. "/pyproject.toml") == 1 or vim.fn.filereadable(path .. "/requirements.txt") == 1 then return "Python" end
  if vim.fn.filereadable(path .. "/pubspec.yaml") == 1 then return "Dart" end
  if vim.fn.filereadable(path .. "/composer.json") == 1 then return "PHP" end
  if vim.fn.filereadable(path .. "/build.gradle") == 1 or vim.fn.filereadable(path .. "/build.gradle.kts") == 1 then return "Java" end
  return ""
end

function M.pick()
  local ws_root, ws_kind = find_workspace()
  if not ws_root then
    vim.notify("未检测到工作区 (package.json/Cargo.toml/go.work 等)", vim.log.levels.WARN)
    return
  end

  local modules = parse_modules(ws_root, ws_kind)

  -- build picker items
  local items = {}
  for _, mod in ipairs(modules) do
    local lang = detect_lang_for_path(mod.path)
    local label = mod.name .. (lang ~= "" and ("  [" .. lang .. "]") or "")
    items[#items + 1] = { label = label, mod = mod }
  end

  -- sort by name
  table.sort(items, function(a, b) return a.mod.name < b.mod.name end)

  -- simple picker
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local list_h = math.min(15, #items + 2)
  local win_w = 55
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_w,
    height = list_h,
    row = math.floor((vim.o.lines - list_h) / 2),
    col = math.floor((vim.o.columns - win_w) / 2),
    style = "minimal",
    border = "rounded",
  })

  local cursor = 1
  local ns = vim.api.nvim_create_namespace("arkvim_modules")

  local function render()
    local lines = {}
    for i, item in ipairs(items) do
      local mark = i == cursor and "> " or "  "
      lines[#lines + 1] = mark .. item.label
    end
    while #lines < list_h do lines[#lines + 1] = "" end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    if cursor >= 1 and cursor <= #items then
      local row = cursor - 1
      if row < #lines then
        vim.api.nvim_buf_add_highlight(buf, ns, "Visual", row, 0, -1)
      end
    end
  end

  local function select()
    local chosen = items[cursor]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if chosen then
      vim.cmd("cd " .. vim.fn.fnameescape(chosen.mod.path))
      -- open main file if any
      local main_candidates = {
        "main.rs", "lib.rs", "main.go", "app.go", "index.ts", "index.js",
        "main.dart", "src/main.c", "src/main.cpp", "app.py", "main.py",
      }
      for _, f in ipairs(main_candidates) do
        local full = chosen.mod.path .. "/" .. f
        if vim.fn.filereadable(full) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(full))
          return
        end
      end
      -- no main file, just show directory
      vim.cmd("edit " .. vim.fn.fnameescape(chosen.mod.path))
    end
  end

  local function cancel()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local km = { buffer = buf, silent = true, nowait = true, noremap = true }
  vim.keymap.set("n", "j", function() cursor = math.max(1, math.min(#items, cursor + 1)); render() end, km)
  vim.keymap.set("n", "<Down>", function() cursor = math.max(1, math.min(#items, cursor + 1)); render() end, km)
  vim.keymap.set("n", "k", function() cursor = math.max(1, math.min(#items, cursor - 1)); render() end, km)
  vim.keymap.set("n", "<Up>", function() cursor = math.max(1, math.min(#items, cursor - 1)); render() end, km)
  vim.keymap.set("n", "<CR>", select, km)
  vim.keymap.set("n", "<Space>", select, km)
  vim.keymap.set("n", "q", cancel, km)
  vim.keymap.set("n", "<Esc>", cancel, km)

  render()
end

function M.setup()
  local map = vim.keymap.set
  map("n", "<leader>mm", function() M.pick() end, { desc = "模块列表", silent = true })
end

return M
