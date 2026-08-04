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
  vim.fn.setfperm(tmp, "755")
  vim.fn.jobstart({ "open", tmp }, { detach = true })
end

local function open_external_terminal(dir)
  if vim.fn.has("mac") == 1 then
    mac_temp_script({ "cd " .. vim.fn.shellescape(dir), "exec " .. detect_shell() })
    return
  end
  local terms = {
    { "gnome-terminal", "--working-directory=" .. dir },
    { "konsole", "--workdir", dir },
    { "alacritty", "--working-directory", dir },
    { "kitty", "--directory", dir },
    { "wezterm", "--working-directory", dir },
    { "xfce4-terminal", "--working-directory", dir },
    { "lxterminal", "--working-directory=" .. dir },
    { "foot", "--working-directory", dir },
    { "urxvt", "-cd", dir },
    { "st", "-e", "cd", dir, ";", vim.o.shell },
    { "terminator", "--working-directory", dir },
    { "tilix", "--working-directory", dir },
    { "xterm", "-e", vim.o.shell, "-c", "cd " .. vim.fn.shellescape(dir) .. " && exec " .. vim.o.shell },
  }
  for _, t in ipairs(terms) do
    if vim.fn.executable(t[1]) == 1 then
      vim.fn.jobstart(t, { detach = true })
      return
    end
  end
  if vim.fn.executable("x-terminal-emulator") == 1 then
    vim.fn.jobstart({ "x-terminal-emulator" }, { detach = true })
    return
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

-- External terminal (auto-detect)
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
