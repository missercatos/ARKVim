-- arkvim/media.lua — 媒体文件（图片/视频/GIF/PDF）的「渲染 ↔ 源码」切换
--
-- 背景：这些格式由 snacks.image 通过 BufReadCmd 接管，buffer 里其实没有内容，
-- 且被设成 modifiable=false。所以想「看二进制」不能只开 modifiable（会是空文件），
-- 必须跳过 snacks 的 BufReadCmd 重新按普通文本读一次（:noautocmd edit!）。
--
--   <leader>uM                 当前缓冲区：渲染 ↔ 源码（自动开 modifiable）
--   :ArkMediaRender on|off|toggle|status   全局开关（只给命令，不给键位）
--
-- 源码视图下保存会弹确认（写回就是直接改文件字节）。

local M = {}

-- snacks.image 支持但拿不到配置时的兜底（与 snacks 默认表一致）
local FALLBACK_FORMATS = {
  "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "heic", "avif",
  "mp4", "mov", "avi", "mkv", "webm", "pdf", "icns",
}

local function formats()
  local ok, snacks = pcall(require, "snacks.image")
  if ok and type(snacks.config) == "table" and type(snacks.config.formats) == "table" then
    return snacks.config.formats
  end
  return FALLBACK_FORMATS
end

local function buf_ext(buf)
  local name = type(buf) == "string" and buf or vim.api.nvim_buf_get_name(buf or 0)
  return name:match("%.([^.]+)$")
end

--- 当前缓冲区（或给一个路径字符串）是不是 snacks.image 会渲染的媒体文件
function M.is_media(buf)
  if type(buf) ~= "string" then
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    if vim.bo[buf].filetype == "image" then
      return true
    end
  end
  local ext = buf_ext(buf)
  return ext ~= nil and vim.tbl_contains(formats(), ext:lower())
end

--- 是不是处在「源码」视图
function M.is_raw(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  return vim.b[buf].arkvim_media_raw == true
end

--- 全局渲染是否开启
function M.global_enabled()
  local ok, snacks = pcall(require, "snacks.image")
  return not (ok and snacks.config and snacks.config.enabled == false)
end

-- ---------------------------------------------------------------------------
-- 切到源码
-- ---------------------------------------------------------------------------
function M.show_raw(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not M.is_media(buf) then
    vim.notify("当前缓冲区不是媒体文件", vim.log.levels.WARN, { title = "ARKVIM" })
    return false
  end

  pcall(function() require("snacks.image").placement.clean(buf) end)

  -- noautocmd：跳过 snacks 的 BufReadCmd（以及文件类型检测），按普通文本读入字节
  pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("noautocmd edit!")
  end)

  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.bo[buf].binary = true
  vim.bo[buf].filetype = ""      -- 别再当 image
  vim.bo[buf].syntax = ""
  vim.b[buf].arkvim_media_raw = true

  vim.notify("已切换为源码（字节）视图，modifiable 已开启", vim.log.levels.INFO, { title = "ARKVIM" })
  return true
end

--- 切回渲染
function M.show_render(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not M.is_raw(buf) then
    return false
  end
  vim.bo[buf].binary = false
  vim.b[buf].arkvim_media_raw = nil
  pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("edit!")   -- 带 autocmd → snacks 重新接管渲染
  end)
  vim.notify("已恢复渲染", vim.log.levels.INFO, { title = "ARKVIM" })
  return true
end

--- 切换（渲染 ↔ 源码）
function M.toggle(buf)
  if M.is_raw(buf) then
    return M.show_render(buf)
  end
  return M.show_raw(buf)
end

-- ---------------------------------------------------------------------------
-- 全局开关
-- ---------------------------------------------------------------------------
function M.global(action)
  local ok, snacks = pcall(require, "snacks.image")
  if not ok or type(snacks.config) ~= "table" then
    vim.notify("snacks.image 未加载", vim.log.levels.WARN, { title = "ARKVIM" })
    return
  end
  local cfg = snacks.config
  if action == "off" then
    cfg.enabled = false
  elseif action == "on" then
    cfg.enabled = true
  elseif action == "toggle" then
    cfg.enabled = not (cfg.enabled ~= false)
  end
  vim.notify(
    "媒体渲染：全局 " .. (cfg.enabled ~= false and "已开启" or "已关闭（新开媒体文件不再渲染）"),
    vim.log.levels.INFO, { title = "ARKVIM" }
  )
end

function M.status()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local lines = {
    "文件: " .. (name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"),
    "是否媒体: " .. (M.is_media(buf) and "是" or "否"),
    "当前视图: " .. (M.is_raw(buf) and "源码(字节)" or "渲染"),
    "全局渲染: " .. (M.global_enabled() and "开启" or "关闭"),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ARKVIM · 媒体" })
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------
function M.setup()
  vim.keymap.set("n", "<leader>uM", function() M.toggle() end,
    { desc = "媒体: 渲染/源码 切换", silent = true })

  vim.api.nvim_create_user_command("ArkMediaRender", function(args)
    local sub = vim.trim(args.args or "")
    if sub == "" or sub == "status" then
      M.status()
    elseif sub == "on" or sub == "off" or sub == "toggle" then
      M.global(sub)
    else
      vim.notify("用法: :ArkMediaRender [on|off|toggle|status]", vim.log.levels.WARN, { title = "ARKVIM" })
    end
  end, {
    nargs = "?",
    desc = "媒体渲染全局开关 (on/off/toggle/status)",
    complete = function() return { "on", "off", "toggle", "status" } end,
  })

  -- 源码视图下保存：弹确认，避免手滑把图片/视频写坏
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = vim.api.nvim_create_augroup("arkvim_media_write", { clear = true }),
    pattern = "*",
    callback = function(args)
      local buf = args.buf
      if not M.is_raw(buf) then
        return   -- 非源码视图：交给 snacks 自己的 BufWriteCmd 处理
      end
      local file = vim.api.nvim_buf_get_name(buf)
      vim.bo[buf].modified = false   -- 先清掉，避免退出的 "No write" 提示
      local choice = vim.fn.confirm(
        string.format("这是 %s 的源码(二进制)视图，保存会直接改写原文件。确定？",
          vim.fn.fnamemodify(file, ":t")),
        "保存\n取消", 2)
      if choice == 1 then
        local ok = pcall(vim.cmd, "noautocmd write!")   -- 跳过 autocmd 真正写回
        if ok then
          vim.notify("已写回: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO, { title = "ARKVIM" })
        else
          vim.notify("写回失败", vim.log.levels.ERROR, { title = "ARKVIM" })
        end
      else
        vim.notify("已取消保存", vim.log.levels.INFO, { title = "ARKVIM" })
      end
      vim.bo[buf].modified = false
    end,
  })
end

return M
