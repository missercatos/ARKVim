-- arkvim/mobile.lua — mobile device helpers (Flutter, Android, Jupyter)

local M = {}

local function run_in_terminal(cmd, title)
  local shell = vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or "bash"

  local full_cmd = cmd .. "; echo; echo 'done'"
  if vim.fn.executable("tmux") == 1 and os.getenv("TMUX") then
    local tmux_cmd = { "tmux", "split-window", "-l", "30%", "-c", vim.fn.getcwd(),
      "bash", "-c", full_cmd .. "; read" }
    vim.fn.jobstart(tmux_cmd, { detach = true })
  else
    local term_cmd = { shell, "-c", full_cmd }
    Snacks.terminal(term_cmd, {
      win = { title = title or "Terminal", position = "float" },
    })
  end
end

-- Flutter: device picker + hot reload
function M.flutter_menu()
  if vim.fn.executable("flutter") ~= 1 then
    vim.notify("flutter 未安装", vim.log.levels.ERROR)
    return
  end
  local devices = vim.fn.systemlist("flutter devices")
  local items = {}
  for _, line in ipairs(devices) do
    local id, rest = line:match("^%s*(%S+)%s+(.*)$")
    if id and id ~= "Flutter" and id ~= "---" then
      table.insert(items, id .. " — " .. (rest or ""))
    end
  end
  if #items == 0 then
    vim.notify("未检测到设备", vim.log.levels.WARN)
    return
  end
  Snacks.picker({
    source = {
      items = items,
      name = "Flutter 设备",
      format = function(item) return item end,
      confirm = function(picker, item)
        if item then
          picker:close()
          local device_id = item:match("^(%S+)")
          if device_id then
            run_in_terminal(
              "cd " .. vim.fn.getcwd() .. " && flutter run -d " .. device_id,
              "Flutter Run"
            )
          end
        end
      end,
    },
  })
end

-- Android: build/install/mirror
function M.android_menu()
  local items = {
    "构建并安装 (gradle build + adb install)",
    "热重载 (gradle install + adb shell am start)",
    "屏幕镜像 (scrcpy)",
    "查看日志 (adb logcat)",
  }
  Snacks.picker({
    source = {
      items = items,
      name = "Android",
      format = function(item) return item end,
      confirm = function(picker, item)
        if item then
          picker:close()
          local proj = require("arkvim.project").current()
          local root = proj and proj.root or vim.fn.getcwd()
          local gw = vim.fn.filereadable(root .. "/gradlew") == 1 and "./gradlew" or "gradle"
          if item:find("构建并安装") then
            run_in_terminal(
              "cd " .. root .. " && " .. gw .. " assembleDebug && adb install -r build/outputs/apk/debug/*.apk",
              "Android Build+Install"
            )
          elseif item:find("热重载") then
            run_in_terminal(
              "cd " .. root .. " && " .. gw .. " installDebug && adb shell am start -S $(grep -oP 'package=\"\\K[^\"]+' app/src/main/AndroidManifest.xml)/.MainActivity",
              "Android Hot Reload"
            )
          elseif item:find("屏幕镜像") then
            if vim.fn.executable("scrcpy") == 1 then
              vim.fn.jobstart({ "scrcpy" }, { detach = true })
              vim.notify("scrcpy 已启动", vim.log.levels.INFO)
            else
              vim.notify("scrcpy 未安装 (pacman -S scrcpy)", vim.log.levels.ERROR)
            end
          elseif item:find("日志") then
            run_in_terminal("adb logcat -d | tail -200", "Android Logcat")
          end
        end
      end,
    },
  })
end

-- Molten: initialize
function M.molten_init()
  vim.cmd("MoltenInit")
  vim.notify("molten 已初始化 — 打开 .ipynb 即可运行", vim.log.levels.INFO)
end

-- Sniprun: run snippet
function M.sniprun_run()
  vim.cmd("SnipRun")
end

return M
