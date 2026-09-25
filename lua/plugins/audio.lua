-- 音频 / 音乐相关插件
-- 统一用 :ArkMusic 开关（实现在 lua/arkvim/music.lua），默认全部关闭。
local is_win = vim.fn.has("win32") == 1
local is_mac = vim.fn.has("mac") == 1
local is_unix = vim.fn.has("unix") == 1

return {
  -- mpv.nvim：mpv 播放器小组件（<leader>Mm / :MpvToggle）
  -- 需要系统装 mpv（+ youtube-dl，若要播放链接）
  {
    "tamton-aquib/mpv.nvim",
    cmd = { "MpvToggle" },
    keys = { { "<leader>Mm", "<cmd>MpvToggle<CR>", desc = "音乐: mpv 播放器" } },
    config = true,
  },

  -- player.nvim：nvim 内置本地音乐播放器
  -- 默认不加载；:ArkMusic player on 时才按需加载并注册快捷键
  -- 注意：作者只在类 Unix 上测过，build.sh 需要 bash；Windows 上我跳过 build
  {
    "jmatth11/player.nvim",
    lazy = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    build = is_unix and "./build.sh" or nil,
    opts = {
      parent_dir = (function()
        local music = vim.fn.expand("~/Music")
        if vim.fn.isdirectory(music) == 1 then
          return music
        end
        return vim.env.HOME or vim.fn.expand("~")
      end)(),
      volume_scale = 5,
      recursive = true,
    },
  },

  -- echo.nvim：跨平台音效播放（作者在原生 Windows / macOS 上测过）
  -- 所以只在 Windows / macOS 默认启用
  -- 依赖它自己的 Rust 二进制（README 说 0.0.1 的 lazy 安装还不行，需手动放二进制）
  {
    "melMass/echo.nvim",
    enabled = is_win or is_mac,
    event = "VeryLazy", -- 放启动之后，万一缺二进制也不拖累启动
    opts = {
      amplify = 0.6,
      events = {
        BufWritePost = { path = "builtin:SUCCESS_2", amplify = 0.6 },
        ExitPre = { path = "builtin:COMPLETE_3", amplify = 0.6 },
      },
    },
  },

  -- ambience.nvim：在 GitHub / 搜索里都找不到这个插件，等用户提供仓库地址再接。
  -- 需求（用户描述）：切到"编码"时播放环境音 / Lo-fi；初始不启用，
  -- 用 :ArkMusic ambience on|off 控制全局默认。
}
