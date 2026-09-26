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
    return c:find("spring-boot", 1, true) ~= nil
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
  { glob = "*.ipynb",        kind = "jupyter",  always = true },

  -- ===== 新增语言 / 框架 =====
  { file = "build.zig",       kind = "zig",      always = true },
  { glob = "*.nimble",        kind = "nim",      always = true },
  { file = "shard.yml",       kind = "crystal",  always = true },
  { file = "dub.json",        kind = "d",        always = true },
  { file = "dub.sdl",         kind = "d",        always = true },
  { glob = "*.cabal",         kind = "haskell",  always = true },
  { file = "stack.yaml",      kind = "haskell",  always = true },
  { file = "cabal.project",   kind = "haskell",  always = true },
  { file = "dune-project",    kind = "ocaml",    always = true },
  { glob = "*.asd",           kind = "lisp",     always = true },
  { file = "info.rkt",        kind = "racket",   always = true },
  { file = "rebar.config",    kind = "erlang",   always = true },
  { file = "mix.exs",         kind = "elixir",   always = true },
  { file = "Project.toml",    kind = "julia",    always = true },
  { file = "Package.swift",   kind = "swift",    always = true },
  { glob = "*.csproj",        kind = "csharp",   always = true },
  { glob = "*.sln",           kind = "csharp",   always = true },
  { file = "deps.edn",        kind = "clojure",  always = true },
  { file = "project.clj",     kind = "clojure",  always = true },
  { file = "build.sbt",       kind = "scala",    always = true },
  { file = "foundry.toml",    kind = "solidity", always = true },
  { file = "flake.nix",       kind = "nix",      always = true },
  { file = "scrapy.cfg",      kind = "python",   always = true },
  { file = "src-tauri/tauri.conf.json", kind = "tauri", always = true },
  { file = "conf.lua",        kind = "love",     always = true },
}

local LANG_MAP = {
  spring = "java", java = "java", gradle = "java", gradle_kotlin = "java",
  rust = "rust", go = "go", node = "typescript", php = "php",
  cmake_c = "c", cmake_cpp = "cpp", python = "python",
  flutter = "dart", dart = "dart", makefile = "make",
  docker_compose = "docker", jupyter = "python",
  zig = "zig", nim = "nim", crystal = "crystal", d = "d",
  haskell = "haskell", ocaml = "ocaml", lisp = "lisp", racket = "racket",
  erlang = "erlang", elixir = "elixir", julia = "julia", swift = "swift",
  csharp = "csharp", clojure = "clojure", scala = "scala",
  solidity = "solidity", nix = "nix", tauri = "rust", love = "lua",
}

--- Walk up from `start` looking for marker files
local function find_root(start)
  local dir = start or vim.fn.getcwd()
  for _ = 1, 20 do
    for _, m in ipairs(MARKERS) do
      local matched
      if m.glob then
        matched = #vim.fn.glob(dir .. "/" .. m.glob, false, true) > 0
      else
        matched = vim.fn.filereadable(dir .. "/" .. m.file) == 1
      end
      if matched then
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
---@param child string
---@param parent string
local function inside(child, parent)
  return child == parent or child:sub(1, #parent + 1) == parent .. "/"
end

local _cache = { start = nil, root = nil, proj = false } -- proj=false 表示“探过了，这里没有项目”

function M.current()
  local file = vim.fn.expand("%:p")
  -- 以“当前文件所在目录”为准；没有真实文件才退回 nvim 的 cwd。
  -- git 必须在文件所在目录里问（git -C），不能用 cwd ——
  -- 否则在 ~/.config/nvim 里打开别的项目的文件时，会把项目认成当前仓库。
  local start = (file ~= "" and file:sub(1, 1) == "/")
      and vim.fn.fnamemodify(file, ":h")
    or vim.fn.getcwd()

  -- 快路径 1：同一个目录，直接复用
  if start == _cache.start then
    return _cache.proj or nil
  end
  -- 快路径 2：还在上次算出的项目里 → 免掉 git 进程 + marker 遍历
  if _cache.proj and inside(start, _cache.root) then
    _cache.start = start
    return _cache.proj
  end

  -- git 仓库根
  local git_root
  local ok, out = pcall(vim.fn.systemlist, { "git", "-C", start, "rev-parse", "--show-toplevel" })
  if ok and vim.v.shell_error == 0 and out and #out > 0 then
    local top = vim.trim(out[1])
    if top ~= "" then git_root = top end
  end

  -- 离当前文件最近的 marker（子项目）
  local nearest = M.detect(start)

  local root, proj
  if git_root then
    local at_root = M.detect(git_root)
    if at_root and at_root.root == git_root then
      -- git 根本身就是项目：多模块 Gradle/Maven、cargo workspace 的构建入口都在根上
      root, proj = git_root, at_root
    elseif nearest and nearest.root ~= git_root and inside(nearest.root, git_root) then
      -- git 根上没有 marker，但文件所在的子目录是一个项目（比如 monorepo 的 packages/x）
      root, proj = nearest.root, nearest
    else
      root, proj = git_root, at_root
    end
  elseif nearest then
    root, proj = nearest.root, nearest
  else
    root = start
    proj = M.detect(start)
  end

  _cache.start = start
  _cache.root = root
  _cache.proj = proj or false
  return proj
end

return M
