-- arkvim/scaffold/cangjie.lua — 仓颉（Cangjie）标准 cjpm 项目模板
--
-- 优先调用官方 `cjpm init`，保证 cjpm.toml 与当前 SDK 匹配；
-- 没有 cjpm 时写一份等价的离线骨架（装好 SDK 后即可 cjpm build）。
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

--- cjpm 的包名必须是合法标识符（不能带 -，不能以数字开头）
local function package_name(name)
  local p = util.snake(name)
  if p == "" then
    p = "app"
  end
  if not p:match("^[%a_]") then
    p = "cj_" .. p
  end
  return p
end

--- cjpm：优先 PATH，其次 ~/.local/share/cangjie/wrappers
local function cjpm_bin()
  if util.executable("cjpm") then
    return "cjpm"
  end
  local p = vim.fn.expand("~/.local/share/cangjie/wrappers/cjpm")
  if util.executable(p) then
    return p
  end
  return nil
end

gen.cjpm = function(target, name)
  local t = util.project_tokens(name)
  local pkg = package_name(name)
  local tokens = vim.tbl_extend("force", t, { package = pkg, snake = pkg })
  local initialized = false

  local cjpm = cjpm_bin()
  if cjpm then
    util.mkdir_p(target)
    vim.fn.system({
      cjpm, "init",
      "--name", pkg,
      "--type=executable",
      "--path", target,
    })
    initialized = vim.v.shell_error == 0
  end

  -- cjpm init 会写 description = "nothing here"，换成项目名
  if initialized then
    local toml = target .. "/cjpm.toml"
    if vim.fn.filereadable(toml) == 1 then
      local lines = vim.fn.readfile(toml)
      local desc = t.NAME:gsub("\\", "\\\\"):gsub('"', '\\"')
      for i, l in ipairs(lines) do
        if l:match("^%s*description%s*=") then
          lines[i] = '  description = "' .. desc .. '"'
        end
      end
      vim.fn.writefile(lines, toml)
    end
  end

  -- 入口：无论 cjpm init 是否成功，都写一份带项目名的示例
  util.write_tree(target, {
    ["src/main.cj"] = util.fill([[package {{package}}

main(): Int64 {
    println("Hello from {{NAME}}!")
    return 0
}
]], tokens),
  })

  -- 离线兜底：cjpm 不可用时也要生成可用的标准骨架
  if not initialized then
    util.write_tree(target, {
      ["cjpm.toml"] = util.fill([=[[package]
  cjc-version = "1.3.0"
  name = "{{package}}"
  organization = ""
  description = "{{NAME}}"
  version = "1.0.0"
  target-dir = ""
  script-dir = ""
  output-type = "executable"
  compile-option = ""
  override-compile-option = ""
  link-option = ""
  package-configuration = {}

[dependencies]
]=], tokens),
    })
  end

  util.write_tree(target, {
    ["README.md"] = util.fill([=[# {{NAME}}

仓颉（Cangjie）标准 `cjpm` 项目。

## 源码

- `src/main.cj`：入口
- `cjpm.toml`：项目配置（包名 `{{package}}`）

## 开发

```bash
cjpm build      # 编译
cjpm run        # 编译并运行
cjpm test       # 单元测试（在 src/ 下添加 *_test.cj）
cjpm clean      # 清理 target/
```

> 需要 Cangjie SDK（`cjc` / `cjpm`）：
> `cangjie install-lts <sdk.tar.gz>` 或 `cangjie update --use`
]=], tokens),
    [".gitignore"] = "target/\n*.cjo\n*.cjdb\n",
  })

  return initialized
      and "仓颉 (cjpm) 项目已生成（cjpm build / cjpm run）"
    or "仓颉 (cjpm) 离线骨架已生成（先安装 Cangjie SDK，再 cjpm build）"
end

M.frameworks = {
  {
    label = "Cangjie (cjpm)",
    lang = "cangjie",
    gen = gen.cjpm,
    main = "src/main.cj",
    requires = {
      bins = { "cjpm", "cjc" },
      note = "需先安装 Cangjie SDK：cangjie install-lts <tar.gz> 或 cangjie update --use",
    },
  },
}

return M
