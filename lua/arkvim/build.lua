-- arkvim/build.lua — project-level build/run/test/clean
-- Uses arkvim.project for detection. Commands run in Snacks.terminal bottom split.

local M = {}

-- ---------------------------------------------------------------------------
-- command tables
-- ---------------------------------------------------------------------------

local function has(cmd) return vim.fn.executable(cmd) == 1 end

local function commands(proj)
  local k = proj.kind or proj.lang
  local root = proj.root
  local cmds = {}

  if k == "spring" then
    cmds.build  = "cd " .. root .. " && mvn -q package -DskipTests"
    cmds.run    = "cd " .. root .. " && mvn -q spring-boot:run"
    cmds.test   = "cd " .. root .. " && mvn -q test"
    cmds.clean  = "cd " .. root .. " && mvn -q clean"
    if has("java") then
      local jars = vim.fn.glob(root .. "/target/*.jar", false, true)
      if #jars > 0 then
        cmds.run_alt = "cd " .. root .. " && java -jar " .. vim.fn.shellescape(jars[1])
      end
    end
  elseif k == "java" then
    if has("javac") and has("java") then
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
      local f = io.open(root .. "/package.json", "r")
      if f then
        local c = f:read("*a"); f:close()
        local ok, pkg = pcall(vim.fn.json_decode, c)
        if ok and pkg.scripts then
          if pkg.scripts.build then cmds.build = "cd " .. root .. " && npm run build" end
          if pkg.scripts.dev then
            cmds.run = "cd " .. root .. " && npm run dev"
          elseif pkg.scripts.start then
            cmds.run = "cd " .. root .. " && npm run start"
          end
          if pkg.scripts.test then cmds.test = "cd " .. root .. " && npm test" end
        end
      end
      cmds.clean = "cd " .. root .. " && rm -rf node_modules dist .next .output"
    end
  elseif k == "php" then
    if has("composer") then cmds.build = "cd " .. root .. " && composer install" end
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
      cmds.build = "cd " .. root .. " && cmake -S . -B build && cmake --build build"
      cmds.clean = "cd " .. root .. " && rm -rf build"
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
      if has("pytest") then cmds.test = "cd " .. root .. " && pytest -q" end
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

function M.project()
  return require("arkvim.project").current()
end

function M.run(action)
  local proj = M.project()
  if not proj then
    vim.notify("未检测到项目 (没有找到 marker 文件)", vim.log.levels.WARN)
    return
  end
  local cmds = commands(proj)
  run_in_terminal(cmds[action])
end

-- ---------------------------------------------------------------------------
-- dynamic keymap registration (<leader>B*)
-- ---------------------------------------------------------------------------

local _registered = false
local _current_root = nil

local KEYMAP_ACTIONS = {
  { lhs = "<leader>Bb", action = "build", desc = "构建项目" },
  { lhs = "<leader>Br", action = "run",   desc = "运行项目" },
  { lhs = "<leader>Bt", action = "test",  desc = "测试项目" },
  { lhs = "<leader>Bc", action = "clean", desc = "清理项目" },
}

local function register_keymaps()
  if _registered then return end
  for _, a in ipairs(KEYMAP_ACTIONS) do
    vim.keymap.set("n", a.lhs, function() M.run(a.action) end,
      { desc = a.desc, silent = true, noremap = true })
  end
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>B", group = "+build", mode = "n" },
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
  local proj = M.project()
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

function M.setup()
  local grp = vim.api.nvim_create_augroup("arkvim_build", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = grp,
    callback = function() vim.schedule(refresh) end,
  })
  vim.schedule(refresh)
end

return M
