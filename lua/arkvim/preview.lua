-- arkvim/preview.lua — real-time preview in independent OS window or nvim split
-- Detects project via build.lua; spawns the right renderer as a Wayland/X11
-- window (niri/hyprland managed) or in a Snacks.terminal split.

local M = {}

local STATE_DIR = vim.fn.stdpath("state") .. "/arkvim"
local STATE_FILE = STATE_DIR .. "/preview.json"

-- ---------------------------------------------------------------------------
-- WM / OS detection
-- ---------------------------------------------------------------------------

local function detect_wm()
  if os.getenv("NIRI_SOCKET") then return "niri" end
  if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then return "hyprland" end
  return nil
end

local function detect_shell()
  local sh = vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or "bash"
  return sh
end

-- ---------------------------------------------------------------------------
-- process management
-- ---------------------------------------------------------------------------

local function state_load()
  vim.fn.mkdir(STATE_DIR, "p")
  if vim.fn.filereadable(STATE_FILE) == 0 then return {} end
  local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(STATE_FILE))
  return (ok and type(data) == "table") and data or {}
end

local function state_save(state)
  vim.fn.mkdir(STATE_DIR, "p")
  vim.fn.writefile({ vim.fn.json_encode(state) }, STATE_FILE)
end

local function state_clear()
  pcall(vim.fn.delete, STATE_FILE)
end

local function is_running(state)
  if not state or not state.pid then return false end
  -- check /proc/<pid> existence
  return vim.fn.isdirectory("/proc/" .. state.pid) == 1
end

local function kill_pid(pid)
  if not pid then return end
  -- kill process group (-pid) first, then the pid itself
  pcall(vim.fn.system, { "kill", "--", tostring(pid) })
  pcall(vim.fn.system, { "kill", "-9", "--", tostring(pid) })
end

-- ---------------------------------------------------------------------------
-- OS window spawn (niri / hyprland / fallback)
-- ---------------------------------------------------------------------------

local function spawn_os(cmd, opts)
  opts = opts or {}
  local wm = detect_wm()
  local shell = detect_shell()

  if wm == "niri" then
    local niri_cmd = "niri msg action spawn-sh -- " .. vim.fn.shellescape(shell .. " -c " .. vim.fn.shellescape(cmd))
    vim.fn.jobstart({ shell, "-c", niri_cmd }, { detach = true })
    return true
  end

  if wm == "hyprland" then
    vim.fn.jobstart({ "hyprctl", "dispatch", "exec", "--", shell, "-c", cmd }, { detach = true })
    return true
  end

  -- fallback: detached jobstart
  vim.fn.jobstart({ shell, "-c", cmd }, { detach = true })
  return true
end

-- ---------------------------------------------------------------------------
-- split spawn (Snacks.terminal)
-- ---------------------------------------------------------------------------

local function spawn_split(cmd)
  local shell = detect_shell()
  Snacks.terminal({ shell, "-c", "clear && " .. cmd }, {
    win = { position = "bottom", height = 0.3 },
  })
end

-- ---------------------------------------------------------------------------
-- preview commands per framework
-- ---------------------------------------------------------------------------

local function has(cmd) return vim.fn.executable(cmd) == 1 end

--- Returns { os_cmd, split_cmd, url? } or nil
local function preview_commands(proj)
  local k = proj.kind or proj.lang
  local root = proj.root

  if k == "node" then
    -- detect dev script
    local f = io.open(root .. "/package.json", "r")
    if f then
      local c = f:read("*a"); f:close()
      local ok, pkg = pcall(vim.fn.json_decode, c)
      if ok and pkg.scripts then
        local dev = pkg.scripts.dev or pkg.scripts.start
        if dev then
          local url = "http://localhost:5173"
          return {
            os_cmd = "cd " .. root .. " && npm run dev -- --host",
            split_cmd = "cd " .. root .. " && npm run dev",
            url = url,
          }
        end
      end
    end
    -- fallback
    if has("npm") then
      return {
        os_cmd = "cd " .. root .. " && npm run dev",
        split_cmd = "cd " .. root .. " && npm run dev",
        url = "http://localhost:5173",
      }
    end
  end

  if k == "flutter" then
    if has("flutter") then
      return {
        os_cmd = "cd " .. root .. " && flutter run -d linux --no-sound-null-safety",
        split_cmd = "cd " .. root .. " && flutter run --no-sound-null-safety",
      }
    end
  end

  if k == "dart" then
    if has("dart") then
      return {
        os_cmd = "cd " .. root .. " && dart run",
        split_cmd = "cd " .. root .. " && dart run",
      }
    end
  end

  if k == "cmake_cpp" or k == "cmake_c" then
    if has("cmake") then
      -- build + run
      local build = "cd " .. root .. " && cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build"
      -- try to find binary
      local bins = vim.fn.glob(root .. "/build/*", false, true)
      local run_bin = nil
      for _, b in ipairs(bins) do
        if vim.fn.filereadable(b) == 1 and vim.fn.getfperm(b):find("x") then
          run_bin = vim.fn.shellescape(b)
          break
        end
      end
      if run_bin then
        return {
          os_cmd = build .. " && " .. run_bin,
          split_cmd = build .. " && " .. run_bin,
        }
      end
      return { os_cmd = build, split_cmd = build }
    end
  end

  if k == "rust" then
    if has("cargo") then
      return {
        os_cmd = "cd " .. root .. " && cargo run",
        split_cmd = "cd " .. root .. " && cargo run",
      }
    end
  end

  if k == "go" then
    if has("go") then
      return {
        os_cmd = "cd " .. root .. " && go run .",
        split_cmd = "cd " .. root .. " && go run .",
      }
    end
  end

  if k == "python" then
    if has("python3") then
      local mod = proj.label and proj.label:gsub("%s+", "_"):lower() or "app"
      return {
        os_cmd = "cd " .. root .. " && python3 -m " .. mod,
        split_cmd = "cd " .. root .. " && python3 -m " .. mod,
      }
    end
  end

  if k == "php" then
    if has("php") and vim.fn.filereadable(root .. "/artisan") == 1 then
      return {
        os_cmd = "cd " .. root .. " && php artisan serve --host=0.0.0.0",
        split_cmd = "cd " .. root .. " && php artisan serve",
        url = "http://localhost:8000",
      }
    end
  end

  if k == "gradle" or k == "gradle_kotlin" then
    local gw = (vim.fn.filereadable(root .. "/gradlew") == 1) and "./gradlew" or "gradle"
    return {
      os_cmd = "cd " .. root .. " && " .. gw .. " bootRun",
      split_cmd = "cd " .. root .. " && " .. gw .. " bootRun",
    }
  end

  if k == "spring" then
    return {
      os_cmd = "cd " .. root .. " && mvn -q spring-boot:run",
      split_cmd = "cd " .. root .. " && mvn -q spring-boot:run",
    }
  end

  -- html / image: open in browser
  if k == "html" or k == "css" then
    local file = vim.fn.expand("%:p")
    if file ~= "" and file:find(root, 1, true) then
      return {
        os_cmd = "xdg-open " .. vim.fn.shellescape(file),
        split_cmd = nil,
        url = file,
      }
    end
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- public API
-- ---------------------------------------------------------------------------

--- Preview in independent OS window (Wayland client)
function M.preview_os()
  local proj = require("arkvim.build").project()
  if not proj then
    vim.notify("未检测到项目", vim.log.levels.WARN)
    return
  end
  local cmds = preview_commands(proj)
  if not cmds or not cmds.os_cmd then
    vim.notify("该框架暂不支持独立窗口预览", vim.log.levels.WARN)
    return
  end
  -- kill existing preview if running
  local state = state_load()
  if is_running(state) then
    kill_pid(state.pid)
  end
  spawn_os(cmds.os_cmd)
  -- save state (pid from jobstart not reliable for detached, use a marker)
  state_save({
    cmd = cmds.os_cmd,
    kind = (proj.kind or proj.lang),
    url = cmds.url,
    cwd = proj.root,
    started = os.time(),
  })
  vim.notify("已启动独立窗口预览")
  -- auto-open URL in browser if available
  if cmds.url and has("xdg-open") then
    vim.fn.jobstart({ "xdg-open", cmds.url }, { detach = true })
  end
end

--- Preview in nvim split (bottom terminal)
function M.preview_split()
  local proj = require("arkvim.build").project()
  if not proj then
    vim.notify("未检测到项目", vim.log.levels.WARN)
    return
  end
  local cmds = preview_commands(proj)
  if not cmds or not cmds.split_cmd then
    vim.notify("该框架暂不支持分割预览", vim.log.levels.WARN)
    return
  end
  local state = state_load()
  if is_running(state) then
    kill_pid(state.pid)
  end
  spawn_split(cmds.split_cmd)
  state_save({
    cmd = cmds.split_cmd,
    kind = (proj.kind or proj.lang),
    url = cmds.url,
    cwd = proj.root,
    started = os.time(),
  })
  if cmds.url then
    vim.notify("预览已启动\n" .. cmds.url)
  end
end

--- Stop running preview
function M.stop()
  local state = state_load()
  if not state or not is_running(state) then
    vim.notify("没有正在运行的预览")
    return
  end
  kill_pid(state.pid)
  state_clear()
  vim.notify("预览已停止")
end

--- Open preview URL in browser
function M.open_browser()
  local state = state_load()
  if state and state.url and has("xdg-open") then
    vim.fn.jobstart({ "xdg-open", state.url }, { detach = true })
  else
    vim.notify("没有可打开的预览地址")
  end
end

-- ---------------------------------------------------------------------------
-- keymaps (called by keymaps.lua)
-- ---------------------------------------------------------------------------

function M.setup()
  local map = vim.keymap.set
  map("n", "<leader>pp", function() M.preview_split() end, { desc = "预览 (分割)", silent = true })
  map("n", "<leader>pP", function() M.preview_os() end, { desc = "预览 (独立窗口)", silent = true })
  map("n", "<leader>ps", function() M.stop() end, { desc = "停止预览", silent = true })
  map("n", "<leader>po", function() M.open_browser() end, { desc = "浏览器打开预览", silent = true })
end

return M
