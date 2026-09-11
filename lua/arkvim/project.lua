-- arkvim/project.lua — unified project detection
-- Shared by build, capabilities, hints. Cache per root.

local M = {}

-- Marker files → project type detection order (first match wins)
local MARKERS = {
  { file = "pubspec.yaml",    kind = "flutter", check = function(root)
    local f = io.open(root .. "/pubspec.yaml", "r")
    if not f then return false end
    local c = f:read("*a"); f:close()
    return c:find("flutter", 1, true) ~= nil
  end},
  { file = "pubspec.yaml",    kind = "dart",    always = true },
  { file = "pom.xml",         kind = "spring",  check = function(root)
    local f = io.open(root .. "/pom.xml", "r")
    if not f then return false end
    local c = f:read("*a"); f:close()
    return c:find("spring%-boot", 1, true) ~= nil
  end},
  { file = "pom.xml",         kind = "java",    always = true },
  { file = "build.gradle.kts", kind = "gradle_kotlin", always = true },
  { file = "build.gradle",    kind = "gradle",   always = true },
  { file = "Cargo.toml",      kind = "rust",     always = true },
  { file = "go.mod",          kind = "go",       always = true },
  { file = "package.json",    kind = "node",     always = true },
  { file = "composer.json",   kind = "php",      always = true },
  { file = "CMakeLists.txt",  kind = "cmake_c",  check = function(root)
    local f = io.open(root .. "/CMakeLists.txt", "r")
    if not f then return false end
    local c = f:read("*a"); f:close()
    return not c:find("CXX") and not c:find("CXX_STANDARD")
  end},
  { file = "CMakeLists.txt",  kind = "cmake_cpp", always = true },
  { file = "pyproject.toml",  kind = "python",   always = true },
  { file = "requirements.txt", kind = "python",  always = true },
  { file = "Makefile",        kind = "makefile", always = true },
  { file = "docker-compose.yml", kind = "docker_compose", always = true },
  { file = "docker-compose.yaml", kind = "docker_compose", always = true },
  { file = ".ipynb",          kind = "jupyter",  always = true },
}

local LANG_MAP = {
  spring = "java", java = "java", gradle = "java", gradle_kotlin = "java",
  rust = "rust", go = "go", node = "typescript", php = "php",
  cmake_c = "c", cmake_cpp = "cpp", python = "python",
  flutter = "dart", dart = "dart", makefile = "make",
  docker_compose = "docker", jupyter = "python",
}

--- Walk up from `start` looking for marker files
local function find_root(start)
  local dir = start or vim.fn.getcwd()
  for _ = 1, 20 do
    for _, m in ipairs(MARKERS) do
      local path = dir .. "/" .. m.file
      if vim.fn.filereadable(path) == 1 then
        if m.check then
          if m.check(dir) then return dir, m.kind end
        else
          return dir, m.kind
        end
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil, nil
end

--- Detect project from current buffer file or cwd. Returns { root, kind, lang, label } or nil
function M.detect(start)
  local file = vim.fn.expand("%:p")
  local s = start or (file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd())
  local root, kind = find_root(s)
  if not root then return nil end

  -- Try scaffold metadata
  local ok, meta = pcall(function()
    return require("arkvim.scaffold").load_metadata(root)
  end)
  if ok and meta and meta.lang then
    return { root = root, lang = meta.lang, kind = meta.kind or kind, label = meta.label or kind }
  end

  return {
    root = root,
    lang = LANG_MAP[kind] or kind,
    kind = kind,
    label = kind,
  }
end

--- Get current project (cached)
local _cache_root = nil
local _cache_proj = nil

function M.current()
  local file = vim.fn.expand("%:p")
  local s = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local ok, out = pcall(vim.fn.systemlist, { "git", "rev-parse", "--show-toplevel" })
  local root = (ok and #out > 0 and vim.v.shell_error == 0) and out[1]
  if not root then root = s end

  if root == _cache_root and _cache_proj then
    return _cache_proj
  end

  _cache_root = root
  _cache_proj = M.detect(root)
  return _cache_proj
end

return M
