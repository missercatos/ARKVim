local keymap = vim.keymap

local function map(mode, lhs, rhs, opts)
  local keys = { noremap = true, silent = true }
  if opts then
    keys = vim.tbl_extend("force", keys, opts)
  end
  keymap.set(mode, lhs, rhs, keys)
end

local function detect_shell()
  return vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or vim.fn.executable("bash") == 1 and "bash"
    or vim.o.shell
end

local function mac_temp_script(lines)
  local tmp = vim.fn.tempname() .. ".command"
  vim.fn.writefile(lines, tmp)
  vim.fn.setfperm(tmp, "rwxr-xr-x")
  vim.fn.jobstart({ "open", tmp }, { detach = true })
end

local function detect_current_terminal()
  -- 1) TERM_PROGRAM (set by most GUI terminals when nvim runs inside them)
  local tp = os.getenv("TERM_PROGRAM")
  if tp and tp ~= "" then return tp:lower() end

  -- 2) tmux / screen
  if os.getenv("TMUX") then return "tmux" end
  if os.getenv("STY") then return "screen" end

  -- 3) parent process name via /proc (Linux)
  local ok, stat = pcall(function()
    local status = vim.fn.readfile("/proc/self/status")
    for _, line in ipairs(status) do
      local ppid = line:match("^PPid:%s*(%d+)")
      if ppid then
        local comm = vim.fn.readfile("/proc/" .. ppid .. "/comm")
        if comm and #comm > 0 then
          return comm[1]:lower():gsub("%s+", "")
        end
      end
    end
    return nil
  end)
  if ok and stat then return stat end

  return nil
end

local function open_external_terminal(dir)
  local cur = detect_current_terminal()
  local shell = detect_shell()

  -- ── tmux: new pane / window ──
  if cur == "tmux" then
    vim.fn.jobstart({ "tmux", "split-window", "-c", dir, "-l", "40%" }, { detach = true })
    return
  end
  if cur == "screen" then
    vim.fn.jobstart({ "screen", "-S", "arkvim-" .. vim.fn.tempname():sub(-6), "-d", "-m", "-r" }, { detach = true })
    return
  end

  -- ── Windows terminals ──
  if vim.fn.has("win32") == 1 or (cur and cur:find("windows%-terminal")) then
    if cur and cur:find("powershell") then
      vim.fn.jobstart({ "powershell", "-NoExit", "-Command", "Set-Location '" .. dir .. "'" }, { detach = true })
      return
    end
    if cur and cur:find("cmd") then
      vim.fn.jobstart({ "cmd", "/K", "cd /d " .. dir }, { detach = true })
      return
    end
    if cur and cur:find("git%-bash") then
      vim.fn.jobstart({ "bash", "--login", "-c", "cd " .. vim.fn.shellescape(dir) .. " && exec " .. shell }, { detach = true })
      return
    end
    -- Windows Terminal / generic: spawn same terminal type
    if vim.fn.executable("wt") == 1 then
      vim.fn.jobstart({ "wt", "-d", dir }, { detach = true })
      return
    end
    -- PowerShell fallback
    vim.fn.jobstart({ "powershell", "-NoExit", "-Command", "Set-Location '" .. dir .. "'" }, { detach = true })
    return
  end

  -- ── macOS terminals ──
  if vim.fn.has("mac") == 1 then
    if cur == "iterm" or cur == "iterm2" then
      mac_temp_script({ "cd " .. vim.fn.shellescape(dir), "exec " .. shell })
      return
    end
    if cur and cur:find("apple%-terminal") then
      mac_temp_script({ "cd " .. vim.fn.shellescape(dir), "exec " .. shell })
      return
    end
    -- iTerm2 CLI (works even when nvim not in iTerm)
    if vim.fn.executable("iterm2") == 1 then
      vim.fn.jobstart({ "iterm2", "--open-in", dir }, { detach = true })
      return
    end
    -- Fallback: Terminal.app via osascript
    mac_temp_script({ "cd " .. vim.fn.shellescape(dir), "exec " .. shell })
    return
  end

  -- ── Linux: spawn same terminal type ──
  local term_cmds = {
    ["kitty"]        = { "kitty", "--directory", dir },
    ["alacritty"]    = { "alacritty", "--working-directory", dir },
    ["wezterm"]      = { "wezterm", "start", "--cwd", dir },
    ["foot"]         = { "foot", "--working-directory", dir },
    ["st"]           = { "st", "-e", "cd", dir, "&&", shell },
    ["urxvt"]        = { "urxvt", "-cd", dir },
    ["xterm"]        = { "xterm", "-e", "cd " .. vim.fn.shellescape(dir) .. " && " .. shell },
    ["terminator"]   = { "terminator", "--working-directory", dir },
    ["tilix"]        = { "tilix", "--working-directory", dir },
    ["lxterminal"]   = { "lxterminal", "--working-directory=" .. dir },
    ["xfce4-terminal"] = { "xfce4-terminal", "--working-directory=" .. dir },
    ["gnome-terminal"] = { "gnome-terminal", "--working-directory=" .. dir },
    ["konsole"]      = { "konsole", "--workdir", dir },
  }
  if cur and term_cmds[cur] then
    vim.fn.jobstart(term_cmds[cur], { detach = true })
    return
  end

  -- ── Fallback: try known terminals by executable ──
  local fallbacks = {
    { "kitty",        { "kitty", "--directory", dir } },
    { "alacritty",    { "alacritty", "--working-directory", dir } },
    { "wezterm",      { "wezterm", "start", "--cwd", dir } },
    { "foot",         { "foot", "--working-directory", dir } },
    { "gnome-terminal", { "gnome-terminal", "--working-directory=" .. dir } },
    { "konsole",      { "konsole", "--workdir", dir } },
    { "xfce4-terminal", { "xfce4-terminal", "--working-directory=" .. dir } },
    { "lxterminal",   { "lxterminal", "--working-directory=" .. dir } },
    { "xterm",        { "xterm", "-e", shell } },
    { "x-terminal-emulator", { "x-terminal-emulator" } },
  }
  for _, t in ipairs(fallbacks) do
    if vim.fn.executable(t[1]) == 1 then
      vim.fn.jobstart(t[2], { detach = true })
      return
    end
  end

  vim.notify("找不到可用的终端模拟器", vim.log.levels.WARN)
end

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
end, { desc = "Terminal below" })

-- External terminal (spawn same terminal type as current)
map("n", "<leader>fT", function()
  open_external_terminal(vim.fn.expand("%:p:h"))
end, { desc = "Terminal (external)" })

local function compile_cmd(file, dir)
  local base = vim.fn.expand("%:t:r")
  local ext = string.lower(vim.fn.expand("%:e"))

  if ext == "c" then
    local cc = vim.fn.executable("gcc") == 1 and "gcc"
      or vim.fn.executable("clang") == 1 and "clang"
    if cc then
      return string.format("%s -Wall -o %s %s && ./%s", cc,
        vim.fn.shellescape(base), vim.fn.shellescape(file), vim.fn.shellescape(base))
    end
    return "echo '错误: 未找到 C 编译器 (gcc/clang)'"
  end
  if ext == "cpp" or ext == "cc" or ext == "cxx" then
    local cpp = vim.fn.executable("g++") == 1 and "g++"
      or vim.fn.executable("clang++") == 1 and "clang++"
    if cpp then
      return string.format("%s -std=c++17 -Wall -o %s %s && ./%s", cpp,
        vim.fn.shellescape(base), vim.fn.shellescape(file), vim.fn.shellescape(base))
    end
    return "echo '错误: 未找到 C++ 编译器 (g++/clang++)'"
  end
  if ext == "java" then
    if vim.fn.executable("javac") == 1 then
      return string.format("javac %s && java -cp %s %s",
        vim.fn.shellescape(file), vim.fn.shellescape(dir), vim.fn.shellescape(base))
    end
    return "echo '错误: 未找到 Java 编译器 (javac)'"
  end
  if ext == "rs" then
    if vim.fn.executable("rustc") == 1 then
      return string.format("rustc %s -o %s && ./%s",
        vim.fn.shellescape(file), vim.fn.shellescape(base), vim.fn.shellescape(base))
    end
    return "echo '错误: 未找到 Rust 编译器 (rustc)'"
  end
  if ext == "go" then
    if vim.fn.executable("go") == 1 then
      return string.format("go run %s", vim.fn.shellescape(file))
    end
    return "echo '错误: 未找到 Go 编译器 (go)'"
  end
  if ext == "zig" then
    if vim.fn.executable("zig") == 1 then
      return string.format("zig run %s", vim.fn.shellescape(file))
    end
    return "echo '错误: 未找到 Zig 编译器 (zig)'"
  end
  if ext == "cs" then
    if vim.fn.executable("mcs") == 1 then
      return string.format("mcs %s && mono %s.exe",
        vim.fn.shellescape(file), vim.fn.shellescape(base))
    end
    return "echo '错误: 未找到 C# 编译器 (mcs)'"
  end
  if ext == "html" then
    vim.fn.jobstart({ "xdg-open", file }, { detach = true })
    vim.notify("浏览器中打开: " .. file)
    return nil, true
  end
  return "echo '不支持编译该文件类型: " .. ext .. "'"
end

-- 编译并运行（底部终端分屏）
map("n", "<leader>k", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local cmd, is_html = compile_cmd(file, dir)
  if is_html then
    return
  end
  local shell = detect_shell()
  Snacks.terminal({ shell, "-c", string.format("clear && %s; echo; echo '按 Enter 退出'; read", cmd) }, {
    cwd = dir,
    win = { position = "bottom", height = 0.25 },
  })
end, { desc = "Compile & run" })

-- 检测 nvim 当前所在终端模拟器
local function detect_terminal()
  local function has_env(name)
    local v = vim.fn.getenv(name)
    return v ~= vim.NIL and v ~= ""
  end
  if has_env("KITTY_WINDOW_ID") or has_env("KITTY_LISTEN_ON") then
    return "kitty"
  end
  if has_env("KONSOLE_VERSION") then
    return "konsole"
  end
  local term = vim.fn.getenv("TERM")
  if type(term) == "string" and term:match("^foot") then
    return "foot"
  end
  return nil
end

-- Compile & run (新开浮动终端窗口，随所在终端模拟器变化)
map("n", "<leader>K", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local cmd, is_html = compile_cmd(file, dir)
  if is_html then
    return
  end
  local shell = detect_shell()
  local full = string.format("cd %s && clear && %s; echo; echo '按 Enter 退出'; read",
    vim.fn.shellescape(dir), cmd)
  local term = detect_terminal()

  if term == "kitty" and vim.fn.executable("kitty") == 1 then
    local env = vim.fn.environ()
    env["KITTY_LISTEN_ON"] = nil
    vim.fn.jobstart({ "kitty", "--class", "nvim-float-term", "--title", "编译运行",
      "--directory", dir, shell, "-c", full }, { detach = true, env = env })
    return
  end

  if term == "konsole" and vim.fn.executable("konsole") == 1 then
    local set_title = string.format("printf '\\033]0;%s\\007'", "编译运行")
    vim.fn.jobstart({ "konsole", "--workdir", dir, "-e", shell, "-c",
      set_title .. " && " .. full }, { detach = true })
    return
  end

  if term == "foot" and vim.fn.executable("foot") == 1 then
    vim.fn.jobstart({ "foot", "--app-id", "nvim-float-term", "--title", "编译运行",
      "--working-directory", dir, shell, "-c", full }, { detach = true })
    return
  end

  vim.notify("无法识别终端模拟器（支持 kitty/konsole/foot），请在其中运行 nvim", vim.log.levels.WARN)
end, { desc = "Compile & run (floating terminal window)" })

-- Terminal mode: Ctrl+HJKL window navigation
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Terminal: move left" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Terminal: move down" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Terminal: move up" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Terminal: move right" })

-- One-key project scaffold: pick language -> framework -> name,
-- the skeleton is created under the current directory.
--   Java: Spring Boot / plain | C,C++: CMake | Go: go module
--   Rust: cargo | Python: package/FastAPI | DevOps: docker compose
map("n", "<leader>pc", function()
  require("arkvim.scaffold").create()
end, { desc = "Scaffold project" })

-- New file (simple: just create and open)
map("n", "<leader>a", function()
  local name = vim.fn.input("新建文件名: ")
  if name == "" then
    return
  end
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  local path = dir .. "/" .. name
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end, { desc = "New file" })

-- Docker / Compose quick actions (bottom built-in terminal)
-- helpers: lua/arkvim/devops.lua
local devops_actions = {
  { "<leader>Dp", function(d) d.compose("ps") end, "Compose: ps" },
  { "<leader>Du", function(d) d.compose("up -d --build") end, "Compose: up -d --build" },
  { "<leader>Dd", function(d) d.compose("down") end, "Compose: down" },
  { "<leader>Db", function(d) d.compose("build") end, "Compose: build" },
  { "<leader>Dl", function(d) d.compose("logs -f --tail 200", true) end, "Compose: logs -f" },
  { "<leader>Ds", function(d) d.run("docker ps -a") end, "Docker: ps" },
  { "<leader>Di", function(d) d.run("docker images") end, "Docker: images" },
  { "<leader>Dx", function(d) d.compose_exec() end, "Compose: exec" },
}
for _, a in ipairs(devops_actions) do
  local fn = a[2]
  map("n", a[1], function()
    fn(require("arkvim.devops"))
  end, { desc = a[3] })
end

-- UI toggle: smear-cursor
map("n", "<leader>us", function()
  local ok, smear = pcall(require, "smear_cursor")
  if ok then
    local state = vim.g.smear_cursor_enabled
    vim.g.smear_cursor_enabled = not state
    vim.notify(state and "光标拖影: 关" or "光标拖影: 开")
  else
    vim.notify("smear-cursor 未加载", vim.log.levels.WARN)
  end
end, { desc = "Toggle smear cursor" })

-- Capability hub
map("n", "<leader>Xh", function()
  require("arkvim.hints").open()
end, { desc = "Capability hub" })

-- which-key group registrations for new keymaps (v3 API: add + group)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>B", group = "+build" },
    { "<leader>G", group = "+Git (gh)" },
    { "<leader>R", group = "+REST" },
    { "<leader>j", group = "+Jupyter" },
    { "<leader>X", group = "+production" },
    { "<leader>A", group = "+AI" },
  })
end

