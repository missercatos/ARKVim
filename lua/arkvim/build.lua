-- arkvim/build.lua — project-level build/run/test/clean/stop
-- Detects project type from marker files and scaffold metadata.
-- Commands run in a reused Snacks.terminal bottom split.

local M = {}

-- ---------------------------------------------------------------------------
-- project detection
-- ---------------------------------------------------------------------------

--- Marker files → project type detection order (first match wins)
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
}

--- Walk up from `start` looking for marker files, return project root or nil
local function find_root(start)
  local dir = start or vim.fn.getcwd()
  -- try each level up to 20 levels
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

--- Detect project from current buffer file or cwd
local function detect()
  local file = vim.fn.expand("%:p")
  local start = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local root, kind = find_root(start)
  if not root then return nil end

  -- Try scaffold metadata first (exact)
  local scaffold = require("arkvim.scaffold")
  local meta = scaffold.load_metadata(root)
  if meta and meta.lang then
    return { root = root, lang = meta.lang, kind = meta.kind or kind, label = meta.label, main = meta.main }
  end

  -- Fallback: infer from marker kind
  local lang_map = {
    spring = "java", java = "java", gradle = "java", gradle_kotlin = "java",
    rust = "rust", go = "go", node = "typescript", php = "php",
    cmake_c = "c", cmake_cpp = "cpp", python = "python",
    flutter = "dart", dart = "dart", makefile = "make",
  }
  return { root = root, lang = lang_map[kind] or kind, kind = kind, label = kind, main = "" }
end

-- ---------------------------------------------------------------------------
-- command tables
-- ---------------------------------------------------------------------------

local function has(cmd) return vim.fn.executable(cmd) == 1 end

--- Returns { build, run, test, clean, stop, main_file? } for a project
local function commands(proj)
  local k = proj.kind or proj.lang
  local root = proj.root
  local cmds = {}

  if k == "spring" then
    cmds.build  = "cd " .. root .. " && mvn -q package -DskipTests"
    cmds.run    = "cd " .. root .. " && mvn -q spring-boot:run"
    cmds.test   = "cd " .. root .. " && mvn -q test"
    cmds.clean  = "cd " .. root .. " && mvn -q clean"
    cmds.stop   = nil
    if has("java") then
      -- find built jar
      local jars = vim.fn.glob(root .. "/target/*.jar", false, true)
      if #jars > 0 then
        cmds.run_alt = "cd " .. root .. " && java -jar " .. vim.fn.shellescape(jars[1])
      end
    end
  elseif k == "java" then
    if has("javac") and has("java") then
      local src = root .. "/src"
      cmds.build = "cd " .. root .. " && find src -name '*.java' | xargs javac -d out"
      cmds.run   = "cd " .. root .. " && java -cp out $(find src -name '*.java' | head -1 | sed 's|src/||;s|\\.java||;s|/|.|g')"
      cmds.clean = "cd " .. root .. " && rm -rf out"
    end
  elseif k == "gradle" or k == "gradle_kotlin" then
    local gw = has("./gradlew") and "./gradlew" or "gradle"
    cmds.build  = "cd " .. root .. " && " .. gw .. " build -x test"
    cmds.run    = "cd " .. root .. " && " .. gw .. " bootRun"
    cmds.test   = "cd " .. root .. " && " .. gw .. " test"
    cmds.clean  = "cd " .. root .. " && " .. gw .. " clean"
  elseif k == "rust" then
    if has("cargo") then
      cmds.build  = "cd " .. root .. " && cargo build"
      cmds.run    = "cd " .. root .. " && cargo run"
      cmds.test   = "cd " .. root .. " && cargo test"
      cmds.clean  = "cd " .. root .. " && cargo clean"
      cmds.stop   = nil
    end
  elseif k == "go" then
    if has("go") then
      cmds.build  = "cd " .. root .. " && go build ./..."
      cmds.run    = "cd " .. root .. " && go run ."
      cmds.test   = "cd " .. root .. " && go test ./..."
      cmds.clean  = "cd " .. root .. " && go clean"
    end
  elseif k == "node" then
    if has("npm") then
      -- parse scripts from package.json
      local f = io.open(root .. "/package.json", "r")
      if f then
        local c = f:read("*a"); f:close()
        local ok, pkg = pcall(vim.fn.json_decode, c)
        if ok and pkg.scripts then
          if pkg.scripts.build then
            cmds.build = "cd " .. root .. " && npm run build"
          end
          if pkg.scripts.dev then
            cmds.run = "cd " .. root .. " && npm run dev"
          elseif pkg.scripts.start then
            cmds.run = "cd " .. root .. " && npm run start"
          end
          if pkg.scripts.test then
            cmds.test = "cd " .. root .. " && npm test"
          end
        end
      end
      cmds.clean = "cd " .. root .. " && rm -rf node_modules dist .next .output"
    end
  elseif k == "php" then
    if has("composer") then
      cmds.build = "cd " .. root .. " && composer install"
    end
    -- detect Laravel artisan
    if vim.fn.filereadable(root .. "/artisan") == 1 then
      cmds.run   = "cd " .. root .. " && php artisan serve"
      cmds.test  = "cd " .. root .. " && php artisan test"
      cmds.clean = "cd " .. root .. " && composer clear-cache"
    end
  elseif k == "flutter" then
    if has("flutter") then
      cmds.build = "cd " .. root .. " && flutter build"
      cmds.run   = "cd " .. root .. " && flutter run"
      cmds.test  = "cd " .. root .. " && flutter test"
      cmds.clean = "cd " .. root .. " && flutter clean"
    end
  elseif k == "dart" then
    if has("dart") then
      cmds.build = "cd " .. root .. " && dart compile exe bin/main.dart"
      cmds.run   = "cd " .. root .. " && dart run"
      cmds.test  = "cd " .. root .. " && dart test"
      cmds.clean = "cd " .. root .. " && dart pub cache clean"
    end
  elseif k == "cmake_c" or k == "cmake_cpp" then
    if has("cmake") then
      cmds.build  = "cd " .. root .. " && cmake -S . -B build && cmake --build build"
      cmds.clean  = "cd " .. root .. " && rm -rf build"
      -- find built binary
      local bins = vim.fn.glob(root .. "/build/*", false, true)
      for _, b in ipairs(bins) do
        if vim.fn.filereadable(b) == 1 and vim.fn.getfperm(b):find("x") then
          cmds.run = "cd " .. root .. " && " .. vim.fn.shellescape(b)
          break
        end
      end
    end
  elseif k == "python" then
    if has("python3") then
      cmds.run   = "cd " .. root .. " && python3 -m " .. (proj.label or "app")
      if has("pytest") then
        cmds.test = "cd " .. root .. " && pytest -q"
      end
      cmds.clean = "cd " .. root .. " && find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; rm -rf .pytest_cache"
    end
  elseif k == "makefile" then
    if has("make") then
      cmds.build = "cd " .. root .. " && make"
      cmds.run   = "cd " .. root .. " && make run"
      cmds.clean = "cd " .. root .. " && make clean"
    end
  end

  return cmds
end

-- ---------------------------------------------------------------------------
-- terminal execution
-- ---------------------------------------------------------------------------

local _term_buf = nil  -- reuse terminal buffer

local function run_in_terminal(cmd)
  if not cmd then
    vim.notify("该操作不支持当前项目类型", vim.log.levels.WARN)
    return
  end
  local full_cmd = string.format("clear && %s; echo; echo '--- 完成 ---'", cmd)
  local shell = vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or "bash"

  Snacks.terminal({ shell, "-c", full_cmd }, {
    win = { position = "bottom", height = 0.25 },
  })
end

-- ---------------------------------------------------------------------------
-- public API
-- ---------------------------------------------------------------------------

--- Get current project info (cached per buffer)
function M.project()
  return detect()
end

--- Run an action: build, run, test, clean, stop
function M.run(action)
  local proj = detect()
  if not proj then
    vim.notify("未检测到项目 (没有找到 marker 文件)", vim.log.levels.WARN)
    return
  end
  local cmds = commands(proj)
  run_in_terminal(cmds[action])
end

-- ---------------------------------------------------------------------------
-- dynamic keymap registration
-- ---------------------------------------------------------------------------

local _registered = false
local _current_root = nil

local KEYMAP_ACTIONS = {
  { lhs = "<leader>rb", action = "build", desc = "构建项目" },
  { lhs = "<leader>rr", action = "run",   desc = "运行项目" },
  { lhs = "<leader>rt", action = "test",  desc = "测试项目" },
  { lhs = "<leader>rc", action = "clean", desc = "清理项目" },
}

local function register_keymaps()
  if _registered then return end
  for _, a in ipairs(KEYMAP_ACTIONS) do
    vim.keymap.set("n", a.lhs, function() M.run(a.action) end,
      { desc = a.desc, silent = true, noremap = true })
  end
  -- which-key group
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>r", group = "+run/build", mode = "n" },
    })
  end
  _registered = true
end

local function unregister_keymaps()
  if not _registered then return end
  for _, a in ipairs(KEYMAP_ACTIONS) do
    pcall(vim.keymap.del, "n", a.lhs)
  end
  _registered = false
end

local function refresh()
  local proj = detect()
  local new_root = proj and proj.root or nil
  if new_root ~= _current_root then
    _current_root = new_root
    if new_root then
      register_keymaps()
    else
      unregister_keymaps()
    end
  end
end

--- Call once at startup
function M.setup()
  local grp = vim.api.nvim_create_augroup("arkvim_build", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = grp,
    callback = function() vim.schedule(refresh) end,
  })
  -- initial check
  vim.schedule(refresh)
end

return M
