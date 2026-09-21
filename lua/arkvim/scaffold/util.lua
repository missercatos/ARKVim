-- arkvim/scaffold/util.lua — 脚手架共享工具 + 依赖检查
-- 通知一律走原生 vim.notify（noice/nvim-notify 特效会自动接管）

local M = {}

local _log = vim.log.levels

--- 原生通知
function M.notify(msg, level, title)
  vim.notify(msg, level or _log.INFO, title and { title = title } or nil)
end

-- ---------------------------------------------------------------------------
-- 字符串/文件工具
-- ---------------------------------------------------------------------------

function M.slug(name)
  local s = string.lower(tostring(name or ""))
  s = s:gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
  return s == "" and "app" or s
end

function M.snake(name)
  return M.slug(name):gsub("-", "_")
end

function M.pascal(name)
  local parts = {}
  for p in M.slug(name):gsub("-", "_"):gsub("_", " "):gmatch("%S+") do
    parts[#parts + 1] = p:sub(1, 1):upper() .. p:sub(2)
  end
  return table.concat(parts)
end

--- 模板变量替换：{{NAME}} {{kebab}} {{snake}} {{Pascal}} {{pkg}}
function M.fill(content, t)
  return (content:gsub("{{(%w+)}}", function(k)
    return t[k] or ("{{" .. k .. "}}")
  end))
end

function M.mkdir_p(dir)
  vim.fn.mkdir(dir, "p")
end

--- 写入文件树 { rel_path = content }
function M.write_tree(root, files)
  for rel, content in pairs(files) do
    local path = root .. "/" .. rel
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then
      lines[#lines] = nil
    end
    vim.fn.writefile(lines, path)
  end
end

function M.project_tokens(name)
  local kebab = M.slug(name)
  return {
    NAME = name,
    kebab = kebab,
    snake = M.snake(name),
    Pascal = M.pascal(name),
    pkg = "com.example." .. M.snake(name),
  }
end

--- 解压并去掉顶层目录
function M.unzip_strip(zip, target)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  vim.fn.system({ "unzip", "-oq", zip, "-d", tmp })
  if vim.v.shell_error ~= 0 then
    vim.fn.system({ "rm", "-rf", tmp })
    return false
  end
  local dirs = vim.fn.glob(tmp .. "/*/", false, true)
  local inner = #dirs == 1 and vim.fn.substitute(dirs[1], "/$", "", "") or tmp
  vim.fn.system({ "cp", "-a", inner .. "/.", target })
  local ok = vim.v.shell_error == 0
  vim.fn.system({ "rm", "-rf", tmp })
  return ok
end

function M.executable(bin)
  return vim.fn.executable(bin) == 1
end

--- 生成随机 UUID（Julia 的 Project.toml 需要）
function M.uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return (template:gsub("[xy]", function(c)
    local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
    return string.format("%x", v)
  end))
end

-- ---------------------------------------------------------------------------
-- 依赖检查（原生通知）
-- ---------------------------------------------------------------------------

--- 只检查不提示：所有 bins 都在 PATH 里才返回 true
---@param req? { bins?: string[], pacman?: string[], pip?: string[], npm?: string[], note?: string }
function M.has(req)
  if not req then
    return true
  end
  for _, bin in ipairs(req.bins or {}) do
    if vim.fn.executable(bin) ~= 1 then
      return false
    end
  end
  return true
end

--- 检查并提示；返回 true=满足
function M.check(req, label)
  if M.has(req) then
    return true
  end
  local missing = {}
  for _, bin in ipairs(req.bins or {}) do
    if vim.fn.executable(bin) ~= 1 then
      missing[#missing + 1] = bin
    end
  end
  local msg = string.format("缺少依赖：%s", table.concat(missing, ", "))
  if req.pacman and #req.pacman > 0 then
    msg = msg .. "\n安装: sudo pacman -S " .. table.concat(req.pacman, " ")
  end
  if req.pip and #req.pip > 0 then
    msg = msg .. "\npip: pip install --user " .. table.concat(req.pip, " ")
  end
  if req.npm and #req.npm > 0 then
    msg = msg .. "\nnpm: npm i -g " .. table.concat(req.npm, " ")
  end
  if req.note then
    msg = msg .. "\n" .. req.note
  end
  M.notify(msg, _log.WARN, "ARKVIM · " .. (label or "依赖检查"))
  return false
end

return M
