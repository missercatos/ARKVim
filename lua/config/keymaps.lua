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

local function run_in_terminal(cmd)
  if vim.fn.has("mac") == 1 then
    mac_temp_script({ "#!/bin/bash", cmd })
    return
  end
  local shell = detect_shell()
  local terms = {
    { "gnome-terminal", "--", shell, "-c", cmd },
    { "konsole", "-e", shell, "-c", cmd },
    { "alacritty", "-e", shell, "-c", cmd },
    { "kitty", shell, "-c", cmd },
    { "wezterm", "start", "--", shell, "-c", cmd },
    { "xfce4-terminal", "-e", shell, "-c", cmd },
    { "lxterminal", "-e", shell, "-c", cmd },
    { "foot", shell, "-c", cmd },
    { "urxvt", "-e", shell, "-c", cmd },
    { "st", "-e", shell, "-c", cmd },
    { "terminator", "-e", shell, "-c", cmd },
    { "tilix", "-e", shell, "-c", cmd },
    { "xterm", "-e", shell, "-c", cmd },
  }
  for _, t in ipairs(terms) do
    if vim.fn.executable(t[1]) == 1 then
      vim.fn.jobstart(t, { detach = true })
      return
    end
  end
  if vim.fn.executable("x-terminal-emulator") == 1 then
    vim.fn.jobstart({ "x-terminal-emulator", "-e", shell, "-c", cmd }, { detach = true })
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
end, { desc = "下方终端" })

-- 外部终端（打开新窗口，自动检测终端模拟器）
map("n", "<leader>fT", function()
  open_external_terminal(vim.fn.expand("%:p:h"))
end, { desc = "外部终端" })

-- 编译并运行（外部终端）
map("n", "<leader>k", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local base = vim.fn.expand("%:t:r")
  local ext = string.lower(vim.fn.expand("%:e"))

  local cmd

  if ext == "c" then
    local cc = vim.fn.executable("gcc") == 1 and "gcc"
      or vim.fn.executable("clang") == 1 and "clang"
    if cc then
      cmd = string.format("%s -Wall -o %s %s && ./%s", cc,
        vim.fn.shellescape(base), vim.fn.shellescape(file), vim.fn.shellescape(base))
    else
      cmd = "echo '错误: 未找到 C 编译器 (gcc/clang)'"
    end
  elseif ext == "cpp" or ext == "cc" or ext == "cxx" then
    local cpp = vim.fn.executable("g++") == 1 and "g++"
      or vim.fn.executable("clang++") == 1 and "clang++"
    if cpp then
      cmd = string.format("%s -std=c++17 -Wall -o %s %s && ./%s", cpp,
        vim.fn.shellescape(base), vim.fn.shellescape(file), vim.fn.shellescape(base))
    else
      cmd = "echo '错误: 未找到 C++ 编译器 (g++/clang++)'"
    end
  elseif ext == "java" then
    if vim.fn.executable("javac") == 1 then
      cmd = string.format("javac %s && java -cp %s %s",
        vim.fn.shellescape(file), vim.fn.shellescape(dir), vim.fn.shellescape(base))
    else
      cmd = "echo '错误: 未找到 Java 编译器 (javac)'"
    end
  elseif ext == "rs" then
    if vim.fn.executable("rustc") == 1 then
      cmd = string.format("rustc %s -o %s && ./%s",
        vim.fn.shellescape(file), vim.fn.shellescape(base), vim.fn.shellescape(base))
    else
      cmd = "echo '错误: 未找到 Rust 编译器 (rustc)'"
    end
  elseif ext == "go" then
    if vim.fn.executable("go") == 1 then
      cmd = string.format("go run %s", vim.fn.shellescape(file))
    else
      cmd = "echo '错误: 未找到 Go 编译器 (go)'"
    end
  elseif ext == "zig" then
    if vim.fn.executable("zig") == 1 then
      cmd = string.format("zig run %s", vim.fn.shellescape(file))
    else
      cmd = "echo '错误: 未找到 Zig 编译器 (zig)'"
    end
  elseif ext == "cs" then
    if vim.fn.executable("mcs") == 1 then
      cmd = string.format("mcs %s && mono %s.exe",
        vim.fn.shellescape(file), vim.fn.shellescape(base))
    else
      cmd = "echo '错误: 未找到 C# 编译器 (mcs)'"
    end
  else
    cmd = "echo '不支持编译该文件类型: " .. ext .. "'"
  end

  local full_cmd = string.format("cd %s && clear && %s; echo; echo '按 Enter 退出'; read",
    vim.fn.shellescape(dir), cmd)

  run_in_terminal(full_cmd)
end, { desc = "编译并运行" })

-- 终端模式下 Ctrl+HJKL 跳转窗口
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端左移" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端下移" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端上移" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端右移" })
