-- arkvim/build.lua — project-level build/run/test/clean
-- Uses arkvim.project for detection. Commands run in Snacks.terminal bottom split.

local M = {}

-- ---------------------------------------------------------------------------
-- command tables
-- ---------------------------------------------------------------------------

local function has(cmd) return vim.fn.executable(cmd) == 1 end

--- 猜 Gradle 该跑哪个 task（Spring→bootRun / Android→installDebug / 其它→run）
--- 注意：很多项目用 convention plugin + version catalog，写的是
--- `alias(libs.plugins.android.application)` / `id("maafw.android.application")`，
--- 所以不能只搜 "com.android.application"。
local function detect_gradle_task(root)
  local candidates = { root .. "/build.gradle.kts", root .. "/build.gradle" }
  for _, sub in ipairs({ "app", "android", "server", "core", "application" }) do
    candidates[#candidates + 1] = root .. "/" .. sub .. "/build.gradle.kts"
    candidates[#candidates + 1] = root .. "/" .. sub .. "/build.gradle"
  end
  candidates[#candidates + 1] = root .. "/gradle/libs.versions.toml"
  candidates[#candidates + 1] = root .. "/settings.gradle.kts"
  candidates[#candidates + 1] = root .. "/settings.gradle"

  local parts = {}
  for _, f in ipairs(candidates) do
    if vim.fn.filereadable(f) == 1 then
      parts[#parts + 1] = table.concat(vim.fn.readfile(f), "\n")
    end
  end
  local all = table.concat(parts, "\n")

  if all:find("org%.springframework%.boot") or all:find("spring%-boot") then
    return "bootRun"
  end

  -- Android 判据：AndroidManifest / convention plugin / version catalog 信号
  local manifests = {
    root .. "/app/src/main/AndroidManifest.xml",
    root .. "/android/src/main/AndroidManifest.xml",
    root .. "/src/main/AndroidManifest.xml",
  }
  local is_android = false
  for _, m in ipairs(manifests) do
    if vim.fn.filereadable(m) == 1 then
      is_android = true
    end
  end
  if not is_android then
    is_android = all:find("com%.android") ~= nil
      or all:find("android%.application") ~= nil
      or all:find("android%.library") ~= nil
      or all:find("libs%.plugins%.android") ~= nil
      or all:find("androidx") ~= nil
  end
  if is_android then
    return "installDebug"
  end
  return "run"
end

local function commands(proj)
  local k = proj.kind or proj.lang
  local root = proj.root
  local cmds = {}

  if k == "spring" then
    -- 优先用项目里的 wrapper（系统里没装 mvn/gradle 也能跑）
    local mvn = vim.fn.executable(root .. "/mvnw") == 1 and "./mvnw" or "mvn"
    cmds.build  = "cd " .. root .. " && " .. mvn .. " -q package -DskipTests"
    cmds.run    = "cd " .. root .. " && " .. mvn .. " -q spring-boot:run"
    cmds.test   = "cd " .. root .. " && " .. mvn .. " -q test"
    cmds.clean  = "cd " .. root .. " && " .. mvn .. " -q clean"
    -- 带 JDWP 调试端口启动，之后可用 :ArkDebug attach 连接
    cmds.debug  = "cd " .. root .. " && " .. mvn .. " spring-boot:run " ..
      '-Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"'
    if has("java") then
      local jars = vim.fn.glob(root .. "/target/*.jar", false, true)
      if #jars > 0 then
        cmds.run_alt = "cd " .. root .. " && java -jar " .. vim.fn.shellescape(jars[1])
      end
    end
  elseif k == "java" then
    if vim.fn.filereadable(root .. "/pom.xml") == 1 then
      -- 普通 Maven 项目（非 Spring Boot）
      local mvn = vim.fn.executable(root .. "/mvnw") == 1 and "./mvnw" or "mvn"
      cmds.build = "cd " .. root .. " && " .. mvn .. " -q package -DskipTests"
      cmds.run   = "cd " .. root .. " && " .. mvn .. " -q exec:java"
      cmds.test  = "cd " .. root .. " && " .. mvn .. " -q test"
      cmds.clean = "cd " .. root .. " && " .. mvn .. " -q clean"
    elseif has("javac") and has("java") then
      local maincls = "$(find src -name '*.java' | head -1 | sed 's|src/||;s|\\.java||;s|/|.|g')"
      cmds.build = "cd " .. root .. " && find src -name '*.java' | xargs javac -d out"
      cmds.run   = "cd " .. root .. " && java -cp out " .. maincls
      cmds.clean = "cd " .. root .. " && rm -rf out"
      cmds.debug = "cd " .. root ..
        " && java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005 -cp out " .. maincls
    end
  elseif k == "gradle" or k == "gradle_kotlin" then
    -- 注意：必须用绝对路径判断 wrapper，executable("./gradlew") 是相对 nvim 的 cwd 的，
    -- 在别的目录里打开项目时会误判成没 wrapper，从而去调系统 gradle（可能根本没装）。
    local gw = vim.fn.executable(root .. "/gradlew") == 1 and "./gradlew" or "gradle"
    local gradle_task = detect_gradle_task(root)
    cmds.build  = "cd " .. root .. " && " .. gw .. " build -x test"
    cmds.run    = "cd " .. root .. " && " .. gw .. " " .. gradle_task
    cmds.test   = "cd " .. root .. " && " .. gw .. " test"
    cmds.clean  = "cd " .. root .. " && " .. gw .. " clean"
    -- Spring/普通 JVM：--debug-jvm 会挂在 5005 等调试器（用 :ArkDebug attach 连）
    -- Android：installDebug 装到设备，之后用 adb/Android Studio 调试
    if gradle_task == "installDebug" then
      cmds.debug = "cd " .. root .. " && " .. gw .. " installDebug"
    else
      cmds.debug = "cd " .. root .. " && " .. gw .. " " .. gradle_task .. " --debug-jvm"
    end
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
      cmds.debug  = "cd " .. root .. " && dlv debug ."
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
            cmds.debug = "cd " .. root .. " && NODE_OPTIONS=--inspect npm run dev"
          elseif pkg.scripts.start then
            cmds.run = "cd " .. root .. " && npm run start"
            cmds.debug = "cd " .. root .. " && NODE_OPTIONS=--inspect npm run start"
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
    elseif vim.fn.filereadable(root .. "/vendor/bin/phpunit") == 1 then
      cmds.test  = "cd " .. root .. " && vendor/bin/phpunit"
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
      cmds.test  = "cd " .. root .. " && ctest --test-dir build --output-on-failure"
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
      cmds.test  = "cd " .. root .. " && make test"
      cmds.clean = "cd " .. root .. " && make clean"
    end
  -- ===== 新增语言 =====
  elseif k == "zig" then
    cmds.build = "cd " .. root .. " && zig build"
    cmds.run   = "cd " .. root .. " && zig build run"
    cmds.test  = "cd " .. root .. " && zig build test"
    cmds.clean = "cd " .. root .. " && rm -rf zig-cache .zig-cache zig-out"
  elseif k == "nim" then
    cmds.build = "cd " .. root .. " && nimble build"
    cmds.run   = "cd " .. root .. " && nimble run"
    cmds.test  = "cd " .. root .. " && nimble test"
    cmds.clean = "cd " .. root .. " && rm -rf nimcache"
  elseif k == "crystal" then
    cmds.build = "cd " .. root .. " && shards build"
    cmds.run   = "cd " .. root .. " && crystal run src/main.cr"
    cmds.test  = "cd " .. root .. " && crystal spec"
    cmds.clean = "cd " .. root .. " && rm -rf bin lib"
  elseif k == "d" then
    cmds.build = "cd " .. root .. " && dub build"
    cmds.run   = "cd " .. root .. " && dub run"
    cmds.test  = "cd " .. root .. " && dub test"
    cmds.clean = "cd " .. root .. " && dub clean"
  elseif k == "haskell" then
    cmds.build = "cd " .. root .. " && cabal build"
    cmds.run   = "cd " .. root .. " && cabal run"
    cmds.test  = "cd " .. root .. " && cabal test"
    cmds.clean = "cd " .. root .. " && cabal clean"
  elseif k == "ocaml" then
    cmds.build = "cd " .. root .. " && dune build"
    cmds.run   = "cd " .. root .. " && dune exec -- ./bin/main.exe"
    cmds.test  = "cd " .. root .. " && dune test"
    cmds.clean = "cd " .. root .. " && dune clean"
  elseif k == "lisp" then
    cmds.run   = "cd " .. root .. " && sbcl --script main.lisp"
    cmds.test  = "cd " .. root .. " && sbcl --non-interactive --eval '(asdf:test-system)'"
  elseif k == "racket" then
    cmds.run   = "cd " .. root .. " && racket main.rkt"
    cmds.test  = "cd " .. root .. " && raco test ."
  elseif k == "erlang" then
    cmds.build = "cd " .. root .. " && rebar3 compile"
    cmds.run   = "cd " .. root .. " && rebar3 shell"
    cmds.test  = "cd " .. root .. " && rebar3 eunit"
    cmds.clean = "cd " .. root .. " && rebar3 clean"
  elseif k == "elixir" then
    cmds.build = "cd " .. root .. " && mix compile"
    cmds.run   = "cd " .. root .. " && mix run --no-halt"
    cmds.test  = "cd " .. root .. " && mix test"
    cmds.clean = "cd " .. root .. " && mix clean"
  elseif k == "julia" then
    cmds.run   = "cd " .. root .. " && julia main.jl"
    cmds.test  = "cd " .. root .. " && julia --project -e 'using Pkg; Pkg.test()'"
  elseif k == "swift" then
    cmds.build = "cd " .. root .. " && swift build"
    cmds.run   = "cd " .. root .. " && swift run"
    cmds.test  = "cd " .. root .. " && swift test"
    cmds.clean = "cd " .. root .. " && swift package clean"
  elseif k == "csharp" then
    cmds.build = "cd " .. root .. " && dotnet build"
    cmds.run   = "cd " .. root .. " && dotnet run"
    cmds.test  = "cd " .. root .. " && dotnet test"
    cmds.clean = "cd " .. root .. " && dotnet clean"
  elseif k == "clojure" then
    cmds.run   = "cd " .. root .. " && clj -M:run"
    cmds.test  = "cd " .. root .. " && clj -X:test"
  elseif k == "scala" then
    cmds.build = "cd " .. root .. " && sbt compile"
    cmds.run   = "cd " .. root .. " && sbt run"
    cmds.test  = "cd " .. root .. " && sbt test"
    cmds.clean = "cd " .. root .. " && sbt clean"
  elseif k == "solidity" then
    cmds.build = "cd " .. root .. " && forge build"
    cmds.test  = "cd " .. root .. " && forge test -vvv"
    cmds.clean = "cd " .. root .. " && forge clean"
  elseif k == "nix" then
    cmds.build = "cd " .. root .. " && nix build"
    cmds.run   = "cd " .. root .. " && nix develop"
    cmds.test  = "cd " .. root .. " && nix flake check"
    cmds.clean = "cd " .. root .. " && rm -rf result"
  elseif k == "love" then
    cmds.run   = "cd " .. root .. " && love ."
  elseif k == "tauri" then
    cmds.build = "cd " .. root .. " && npm run tauri build"
    cmds.run   = "cd " .. root .. " && npm run tauri dev"
    cmds.test  = "cd " .. root .. " && cargo test --manifest-path src-tauri/Cargo.toml"
    cmds.clean = "cd " .. root .. " && rm -rf src-tauri/target dist"
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
  local os_util = require("arkvim.os")
  local win = { position = "bottom", height = 0.25 }

  if os_util.is_win then
    local full = os_util.cd_cmd(cmd) .. "; Write-Host ''; Write-Host '--- 完成 ---'"
    Snacks.terminal(os_util.shell_argv(full), { win = win })
    return
  end

  local full_cmd = string.format("clear && %s; echo; echo '--- 完成 ---'", cmd)
  local shell = vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or "bash"

  Snacks.terminal({ shell, "-c", full_cmd }, { win = win })
end

-- ---------------------------------------------------------------------------
-- public API
-- ---------------------------------------------------------------------------

function M.project()
  return require("arkvim.project").current()
end

local ACTION_LABEL = { build = "构建", run = "运行", test = "测试", clean = "清理", debug = "调试" }

function M.run(action)
  local proj = M.project()
  if not proj then
    vim.notify(
      "未检测到项目（从文件所在目录向上找不到 marker 文件）\n目录: " .. vim.fn.getcwd(),
      vim.log.levels.WARN, { title = "ARKVIM · build" })
    return
  end
  local cmds = commands(proj)
  local cmd = cmds[action]
  if not cmd then
    local avail = vim.tbl_map(function(a) return ACTION_LABEL[a] or a end, vim.tbl_keys(cmds))
    table.sort(avail)
    vim.notify(
      string.format("项目类型 %s 不支持「%s」\n可用: %s",
        proj.kind or proj.lang or "?", ACTION_LABEL[action] or action,
        #avail > 0 and table.concat(avail, " / ") or "无"),
      vim.log.levels.WARN, { title = "ARKVIM · build" })
    return
  end
  run_in_terminal(cmd)
end

--- 调试启动命令（按项目类型）
function M.debug_command(proj)
  if not proj then
    return nil
  end
  return commands(proj).debug
end

--- 在底部终端里执行命令（给 dap.lua 用）
function M.run_command(cmd)
  run_in_terminal(cmd)
end

-- ---------------------------------------------------------------------------
-- watch-build：保存文件时自动重新构建/测试（不依赖外部 watchexec/entr）
-- ---------------------------------------------------------------------------

local _watch = { enabled = false, action = "build", root = nil, timer = nil }

--- 后台静默执行，失败时用原生通知
local function run_silent(cmd, label)
  local os_util = require("arkvim.os")
  local argv = os_util.is_win and os_util.silent_argv(os_util.cd_cmd(cmd)) or { "sh", "-c", cmd }
  vim.fn.jobstart(argv, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify(string.format("%s 失败 (exit %d)", label, code), vim.log.levels.ERROR)
      end
    end,
  })
end

function M.watch_active()
  return _watch.enabled
end

--- 开关 watch：保存时自动跑 build（或 test/run）
function M.toggle_watch(action)
  if _watch.enabled then
    _watch.enabled = false
    if _watch.timer then
      _watch.timer:stop()
      _watch.timer:close()
      _watch.timer = nil
    end
    vim.notify("watch 已关闭", vim.log.levels.INFO)
    return
  end
  local proj = M.project()
  if not proj then
    vim.notify("未检测到项目，无法开启 watch", vim.log.levels.WARN)
    return
  end
  _watch.enabled = true
  _watch.action = action or "build"
  _watch.root = proj.root
  vim.notify("watch 已开启：保存文件时自动 " .. _watch.action .. "（再按一次关闭）", vim.log.levels.INFO)
end

local function schedule_watch_build()
  if not _watch.enabled then return end
  if _watch.timer then
    _watch.timer:stop()
  else
    _watch.timer = vim.uv.new_timer()
  end
  _watch.timer:start(500, 0, vim.schedule_wrap(function()
    if not _watch.enabled then return end
    local proj = M.project()
    if not proj then return end
    local cmd = commands(proj)[_watch.action]
    if cmd then
      run_silent(cmd, "watch-" .. _watch.action)
    end
  end))
end

-- ---------------------------------------------------------------------------
-- keymaps (<leader>B*)
-- ---------------------------------------------------------------------------

local KEYMAP_ACTIONS = {
  { lhs = "<leader>Bb", action = "build", desc = "构建项目" },
  { lhs = "<leader>Br", action = "run",   desc = "运行项目" },
  { lhs = "<leader>Bt", action = "test",  desc = "测试项目" },
  { lhs = "<leader>Bc", action = "clean", desc = "清理项目" },
}

local _registered = false

--- 键位始终注册。
--- 之前是「检测到项目才注册」：一旦项目没识别出来（cwd 在别的 git 仓库里、
--- 或者文件在一个没有 marker 的仓库里），<leader>Bt 会静默消失，
--- 按下去完全没反应，很难排查。
local function register_keymaps()
  if _registered then return end
  for _, a in ipairs(KEYMAP_ACTIONS) do
    vim.keymap.set("n", a.lhs, function() M.run(a.action) end,
      { desc = a.desc, silent = true, noremap = true })
  end
  -- watch：保存时自动重跑
  vim.keymap.set("n", "<leader>Bw", function() M.toggle_watch("build") end,
    { desc = "watch 构建 (保存自动)", silent = true, noremap = true })
  vim.keymap.set("n", "<leader>BW", function() M.toggle_watch("test") end,
    { desc = "watch 测试 (保存自动)", silent = true, noremap = true })
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>B", group = "+build", mode = "n" },
    })
  end
  _registered = true
end

function M.setup()
  register_keymaps()
  -- watch-build：保存时自动重跑
  local grp = vim.api.nvim_create_augroup("arkvim_build", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = grp,
    callback = function(args)
      if not _watch.enabled or not _watch.root then
        return
      end
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= "" and name:sub(1, #_watch.root) == _watch.root then
        schedule_watch_build()
      end
    end,
  })
end

return M
