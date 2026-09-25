-- arkvim/music.lua — 音频/音乐统一开关
--
--   :ArkMusic player   [on|off|toggle]   nvim 内置本地音乐播放器（player.nvim）
--   :ArkMusic autoplay [on|off|toggle]   打开音频文件自动用 mpv 播放，离开缓冲区停止
--   :ArkMusic mpv                        唤出 mpv 播放器小组件（mpv.nvim）
--   :ArkMusic echo     [test]            试听 echo.nvim 音效（Windows/macOS 默认启用）
--   :ArkMusic ambience [on|off]          环境音（插件待定，见下）
--   :ArkMusic status
--
-- 默认全部关闭，只有 :ArkMusic ... on 之后才有对应快捷键。

local M = {}

M.state = {
  player = false,   -- player.nvim
  autoplay = false, -- 缓冲区自动播放
}

-- 会自动播放的音频扩展名
local AUDIO_EXTS = {
  "mp3", "flac", "wav", "ogg", "oga", "opus", "m4a", "aac",
  "wma", "ape", "aiff", "aif", "alac", "mid",
}

local function ext_of(buf)
  local name = type(buf) == "string" and buf or vim.api.nvim_buf_get_name(buf or 0)
  return name:match("%.([^.]+)$")
end

function M.is_audio(buf)
  local ext = ext_of(buf)
  return ext ~= nil and vim.tbl_contains(AUDIO_EXTS, ext:lower())
end

local function has(bin)
  return vim.fn.executable(bin) == 1
end

-- ---------------------------------------------------------------------------
-- player.nvim（本地音乐播放器，默认关闭）
-- ---------------------------------------------------------------------------

local PLAYER_KEYS = {
  { "<leader>Mf", function() require("player").file_select() end, "音乐: 选择文件" },
  { "<leader>Mp", function() require("player").player_info() end, "音乐: 播放器面板" },
  { "<leader>MR", function() require("player").resume() end, "音乐: 继续" },
  { "<leader>MS", function() require("player").pause() end, "音乐: 暂停" },
}

local function register_player_keys()
  for _, k in ipairs(PLAYER_KEYS) do
    vim.keymap.set("n", k[1], k[2], { desc = k[3], silent = true })
  end
end

local function unregister_player_keys()
  for _, k in ipairs(PLAYER_KEYS) do
    pcall(vim.keymap.del, "n", k[1])
  end
end

-- player.nvim 的原生库是否已构建（build.sh 的产物）
local function player_lib_ok()
  local dir = vim.fn.stdpath("data") .. "/lazy/player.nvim/zig-out/lib/"
  for _, f in ipairs({ "libplayer_nvim.so", "libplayer_nvim.dylib", "player_nvim.dll" }) do
    if vim.fn.filereadable(dir .. f) == 1 then
      return true
    end
  end
  return false
end

function M.set_player(on)
  if on then
    -- 先确认原生库在，否则 require("player") 会直接抛 "无法打开共享目标文件"
    if not player_lib_ok() then
      vim.notify(
        "player.nvim 还没构建好（缺少 zig-out/lib/libplayer_nvim.so）\n" ..
        "先执行: :Lazy build player.nvim\n" ..
        "（会自动下载 Zig 并编译，需要联网，首次几分钟）",
        vim.log.levels.ERROR, { title = "ARKVIM" })
      return false
    end
    local ok = pcall(require("lazy").load, { plugins = { "player.nvim" }, force = true })
    if not ok or package.loaded["player"] == nil then
      vim.notify("player.nvim 加载失败（原生库有问题？试试 :Lazy build player.nvim）",
        vim.log.levels.ERROR, { title = "ARKVIM" })
      return false
    end
    M.state.player = true
    register_player_keys()
    vim.notify("本地音乐播放器：已开启\n<leader>Mf 选歌 · <leader>Mp 面板", vim.log.levels.INFO, { title = "ARKVIM" })
  else
    M.state.player = false
    unregister_player_keys()
    pcall(function() require("player").pause() end)
    vim.notify("本地音乐播放器：已关闭", vim.log.levels.INFO, { title = "ARKVIM" })
  end
  return true
end

-- ---------------------------------------------------------------------------
-- 自动播放（打开音频文件 → mpv 播放；离开缓冲区停止）
-- ---------------------------------------------------------------------------

local autoplay_job = nil
local autoplay_buf = nil

local function stop_autoplay()
  if autoplay_job then
    pcall(vim.fn.jobstop, autoplay_job)
    autoplay_job = nil
  end
  autoplay_buf = nil
end

function M.play_buffer(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not M.is_audio(buf) then
    return false
  end
  if autoplay_buf == buf and autoplay_job then
    return true -- 同一个缓冲区，已经在播
  end
  stop_autoplay()
  if not has("mpv") then
    vim.notify("未安装 mpv，无法播放", vim.log.levels.WARN, { title = "ARKVIM" })
    return false
  end
  local file = vim.api.nvim_buf_get_name(buf)
  autoplay_job = vim.fn.jobstart({ "mpv", "--no-video", "--really-quiet", file }, { detach = false })
  autoplay_buf = buf
  vim.notify("▶ " .. vim.fn.fnamemodify(file, ":t") .. "  (离开缓冲区停止)", vim.log.levels.INFO, { title = "ARKVIM" })
  return true
end

function M.set_autoplay(on)
  M.state.autoplay = on
  if not on then
    stop_autoplay()
  end
  vim.notify("音频自动播放：" .. (on and "已开启（打开音频文件即播放，离开停止）" or "已关闭"),
    vim.log.levels.INFO, { title = "ARKVIM" })
  return true
end

-- ---------------------------------------------------------------------------
-- 其它
-- ---------------------------------------------------------------------------

--- mpv 小组件（mpv.nvim）
function M.mpv_toggle()
  if not has("mpv") then
    vim.notify("未安装 mpv", vim.log.levels.ERROR, { title = "ARKVIM" })
    return
  end
  pcall(vim.cmd, "MpvToggle")
end

--- echo.nvim 音效试听
function M.echo_test()
  local ok, echo = pcall(require, "echo")
  if not ok then
    vim.notify("echo.nvim 未加载（仅 Windows/macOS 默认启用，且需要它的 Rust 二进制）",
      vim.log.levels.WARN, { title = "ARKVIM" })
    return
  end
  pcall(function() echo.play_sound("builtin:SUCCESS_2") end)
  vim.notify("echo.nvim：播放 builtin:SUCCESS_2", vim.log.levels.INFO, { title = "ARKVIM" })
end

function M.status()
  local buf = vim.api.nvim_get_current_buf()
  local mpv_ok = has("mpv")
  local play_loaded = package.loaded["player"] ~= nil
  local echo_loaded = package.loaded["echo"] ~= nil
  vim.notify(table.concat({
    "当前文件是否音频: " .. (M.is_audio(buf) and "是" or "否"),
    "自动播放: " .. (M.state.autoplay and "开" or "关"),
    "本地播放器(player.nvim): " .. (M.state.player and "开" or "关") ..
      (play_loaded and "（已加载）" or "（未加载）"),
    "  player.nvim 原生库: " .. (player_lib_ok() and "已构建" or "未构建 → :Lazy build player.nvim"),
    "mpv: " .. (mpv_ok and "已安装" or "未安装") .. " · mpv.nvim: " ..
      (package.loaded["mpv"] and "已加载" or "按需"),
    "echo.nvim: " .. (echo_loaded and "已加载" or "未启用/未构建"),
    "ambience.nvim: 未找到该插件（见 README）",
  }, "\n"), vim.log.levels.INFO, { title = "ARKVIM · 音乐" })
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------
function M.setup()
  -- 自动播放的钩子（受 M.state.autoplay 控制）
  local grp = vim.api.nvim_create_augroup("arkvim_music", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = grp,
    pattern = "*",
    callback = function(args)
      if M.state.autoplay then
        M.play_buffer(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "BufHidden", "BufDelete", "VimLeavePre" }, {
    group = grp,
    callback = function()
      if M.state.autoplay then
        stop_autoplay()
      end
    end,
  })

  vim.keymap.set("n", "<leader>Mm", function() M.mpv_toggle() end, { desc = "音乐: mpv 播放器", silent = true })
  vim.keymap.set("n", "<leader>Me", function() M.echo_test() end, { desc = "音乐: 音效试听", silent = true })

  vim.api.nvim_create_user_command("ArkMusic", function(args)
    local parts = vim.split(vim.trim(args.args or ""), "%s+", { plain = false })
    local target = parts[1] or ""
    local action = parts[2] or ""

    local function toggle_of(cur)
      if action == "on" then return true end
      if action == "off" then return false end
      return not cur -- 默认 toggle
    end

    if target == "" or target == "status" then
      M.status()
    elseif target == "player" then
      M.set_player(toggle_of(M.state.player))
    elseif target == "autoplay" then
      M.set_autoplay(toggle_of(M.state.autoplay))
    elseif target == "mpv" then
      M.mpv_toggle()
    elseif target == "echo" then
      M.echo_test()
    elseif target == "ambience" then
      vim.notify(
        "ambience.nvim：在 GitHub 上找不到这个插件（也搜不到 lofi/ambience 类的同名项目）。\n" ..
        "把仓库地址发我，我再接进来；`on|off` 的全局默认开关我会一起做。",
        vim.log.levels.WARN, { title = "ARKVIM" })
    else
      vim.notify("用法: :ArkMusic [player|autoplay|mpv|echo|ambience|status] [on|off|toggle]",
        vim.log.levels.WARN, { title = "ARKVIM" })
    end
  end, {
    nargs = "*",
    desc = "音乐/音频开关 (player/autoplay/mpv/echo/ambience/status)",
    complete = function()
      return { "player", "autoplay", "mpv", "echo", "ambience", "status" }
    end,
  })
end

return M
