-- arkvim/elisp.lua — Emacs Lisp 支持
--
-- 补全方案：Emacs Lisp 目前没有通用 LSP（唯一带补全的 Ellsp 只支持 Eask 项目），
-- 所以这里直接复用本机 Emacs：用 `emacs -Q --batch` 一次性导出 obarray 里的
-- 所有已知符号（内置 + 预加载 + 常用库），缓存到内存/磁盘，再交给 blink.cmp 的
-- omni(complete-func) 源做前缀补全。毫秒级、离线、无需额外安装任何东西。
--
-- 语法高亮走 tree-sitter（自定义 parser，见 lua/plugins/elisp.lua +
-- after/queries/elisp/）。

local M = {}

-- 符号缓存有效期（秒）。过期会后台重新生成，不影响使用。
local CACHE_TTL = 7 * 24 * 3600

-- Emacs 端脚本：加载常用库后把 obarray 里所有符号名按行打印出来。
-- -Q 跳过用户 init，保证快且不受用户配置错误影响。
local EMACS_EXPORT = table.concat({
  "(progn",
  "  (require 'cl-lib nil t)",
  "  (require 'seq nil t)",
  "  (require 'subr-x nil t)",
  "  (require 'pcase nil t)",
  "  (require 'rx nil t)",
  "  (require 'map nil t)",
  "  (let (syms)",
  "    (mapatoms (lambda (s) (push (symbol-name s) syms)))",
  "    (dolist (s (sort syms #'string<))",
  "      (princ s)",
  "      (terpri))))",
}, "\n")

-- elisp 符号允许的字符（用于反查补全起点）
local SYMBOL_CHARS = {}
do
  local function add(chars)
    for i = 1, #chars do
      SYMBOL_CHARS[chars:sub(i, i)] = true
    end
  end
  add("abcdefghijklmnopqrstuvwxyz")
  add("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  add("0123456789")
  add("!$%&*+-./:<=>?@^_~#")
end

-- 内存中的符号表（已排序）
local symbols = {}
local loading = false

local function emacs_bin()
  return vim.fn.executable("emacs") == 1 and "emacs" or nil
end

local function cache_file()
  return vim.fn.stdpath("cache") .. "/arkvim-elisp-symbols.txt"
end

local function normalize(lines)
  local out = {}
  for _, line in ipairs(lines or {}) do
    line = line:gsub("\r$", "")
    if line ~= "" then
      out[#out + 1] = line
    end
  end
  table.sort(out)
  return out
end

--- 从磁盘缓存读取符号表
function M.load_cache()
  local f = cache_file()
  if vim.fn.filereadable(f) == 0 then
    return false
  end
  local list = normalize(vim.fn.readfile(f))
  if #list == 0 then
    return false
  end
  symbols = list
  return true
end

--- 同步生成符号表（首次、无缓存时用，约 60~200ms）
function M.refresh_sync()
  local bin = emacs_bin()
  if not bin then
    return false
  end
  local list = normalize(vim.fn.systemlist({ bin, "-Q", "--batch", "--eval", EMACS_EXPORT }))
  if #list == 0 then
    return false
  end
  symbols = list
  vim.fn.writefile(list, cache_file())
  return true
end

--- 后台异步重新生成符号表（不阻塞编辑）
function M.refresh_async()
  if loading then
    return
  end
  local bin = emacs_bin()
  if not bin then
    return
  end
  loading = true
  local out = {}
  vim.fn.jobstart({ bin, "-Q", "--batch", "--eval", EMACS_EXPORT }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(out, data)
      end
    end,
    on_exit = function(_, code)
      loading = false
      if code == 0 then
        local list = normalize(out)
        if #list > 0 then
          symbols = list
          vim.fn.writefile(list, cache_file())
        end
      end
    end,
  })
end

--- 确保符号表可用（打开 elisp 文件时调用）
function M.ensure_symbols()
  if #symbols > 0 then
    return
  end
  local st = vim.uv.fs_stat(cache_file())
  if st then
    M.load_cache()
    if os.time() - st.mtime.sec >= CACHE_TTL then
      M.refresh_async()
    end
    return
  end
  -- 首次：同步生成，保证第一个补全请求就有结果
  if not M.refresh_sync() then
    M.refresh_async()
  end
end

--- 供测试/调试：返回当前符号表
function M.symbols()
  return symbols
end

--- blink.cmp / Vim 的 omnifunc 实现
---@param findstart integer 1=问起点，0=要候选
---@param base string 已输入前缀
function M.omnifunc(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] -- 光标前的字节数
    local start = col
    while start > 0 and SYMBOL_CHARS[line:sub(start, start)] do
      start = start - 1
    end
    return start
  end

  if base == "" or #symbols == 0 then
    return {}
  end
  local out = {}
  for _, s in ipairs(symbols) do
    if vim.startswith(s, base) then
      out[#out + 1] = s
      if #out >= 2000 then -- 上限，避免极端输入卡菜单
        break
      end
    end
  end
  return out
end

--- 注册文件类型 / 补全 / 命令（启动早期调用）
function M.setup()
  -- Neovim 默认把 .el 当 lisp；改成 elisp 才能用 tree-sitter elisp parser 和补全。
  vim.filetype.add({
    extension = { el = "elisp" },
    pattern = { ["%.emacs$"] = "elisp" },
  })

  local grp = vim.api.nvim_create_augroup("arkvim_elisp", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "elisp",
    callback = function(ev)
      vim.bo[ev.buf].omnifunc = "v:lua.require'arkvim.elisp'.omnifunc"
      M.ensure_symbols()
    end,
  })

  vim.api.nvim_create_user_command("ArkElispSymbols", function()
    symbols = {}
    if M.refresh_sync() then
      vim.notify(("已刷新 Emacs 符号：%d 个"):format(#symbols), vim.log.levels.INFO,
        { title = "ARKVIM · elisp" })
    else
      vim.notify("刷新失败：未找到 emacs 可执行文件", vim.log.levels.WARN, { title = "ARKVIM · elisp" })
    end
  end, { desc = "elisp: 重新导出 Emacs 符号（补全用）" })
end

return M
