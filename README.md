# ARKVIM

基于 LazyVim 的 Neovim 配置，支持语言工具链自动检测，仅在有对应编译器/解释器时启用相关插件。

## 前置要求

- Neovim >= 0.9.0（[下载](https://github.com/neovim/neovim/releases)）
- git
- 终端模拟器支持真彩色（24-bit color）

首次启动时 lazy.nvim 会自动安装，无需手动安装插件管理器。

## 安装

```bash
# 备份现有配置
mv ~/.config/nvim ~/.config/nvim.bak

# 克隆配置
git clone https://github.com/missercatos/ARKVim.git ~/.config/nvim

# 启动 Neovim，自动安装所有插件
nvim
```

## 支持的语言

C、C++、Rust、Python、Java、Kotlin、Go、JavaScript、TypeScript、HTML、CSS、Dockerfile / Compose、Ruby、Lua、Dart / Flutter、PHP，
以及通过 `:ArkTrail`/构建系统覆盖的 Zig、Nim、Crystal、D、Haskell、OCaml、Lisp、Scheme、Racket、Erlang、Elixir、Julia、Swift、C#、Clojure、Scala、Solidity、Nix 等（脚手架共 35 种语言 / 100 个模板）。

每种语言自动配置以下功能（前提是系统中已安装对应工具链）：

| 功能 | 工具 |
|---|---|
| 智能补全（LSP） | clangd / rust-analyzer / basedpyright / ts_ls / jdtls / dockerls / compose LS / solargraph / lua_ls / ... |
| 自动格式化 | clang-format / rustfmt / ruff / prettier / stylua / rubocop / ... |
| 代码检查 | clang-tidy / clippy / ruff / mypy / eslint / hadolint / luacheck / ... |
| 调试 | codelldb / debugpy / ... |

## 快捷键

| 快捷键 | 功能 |
|---|---|
| `<space>ft` | 内置底部终端（当前文件所在目录） |
| `<space>fT` | 外部终端窗口（自动检测当前终端类型，开同类型新窗口） |
| `<space>k` | 编译并运行当前文件（底部内置终端） |
| `<space>K` | 编译并运行当前文件（新开外部终端窗口） |
| `<space>e` / `<space>E` | Snacks 文件树（根目录 / cwd），文件树内删除为 `<space>fd`（File→Delete） |
| `<space>a` | 文件树内新建：光标在文件夹上→创建在该文件夹内；在文件上→创建在同一目录。输入结尾带 `/` 创建目录。 |
| `<space>A` | 文件树内新建（从 cwd 根目录开始）：需写完整路径如 `src/main.java` 或 `a/b/`。 |
| `<space>o` / `<space>O` | oil.nvim 文件管理器（浮动，当前目录 / cwd） |
| `-` | oil.nvim 打开上级目录（vim-vinegar 风格） |
| `<space>pc` | **一键创建框架工程**（选语言 → 选模板 → 输入项目名，共 100 个模板） |
| `<space>Bb/Br/Bt/Bc` | 构建 / 运行 / 测试 / 清理当前项目 |
| `<space>Bw` / `<space>BW` | watch 模式：保存文件自动重跑 build / test（再按一次关闭） |
| `<space>Bo` / `<space>BR` | overseer 任务面板 / 运行任务 |
| `<space>tw` / `<space>tW` / `<space>tq` | 实时测试：watch 当前文件 / 整个项目 / 停止全部 |
| `<space>us` 或 `:ArkTrail` | 光标拖影开关（见下方「光标拖影」） |
| `<space>yd` | duplicate.nvim 复制当前行 / 选区 |
| `<C-n>` | vim-visual-multi 多光标：选中后逐次 `<C-n>` 添加下一个匹配 |
| `<space>D…` | Docker / Compose 快捷操作（见下方 DevOps） |

### 光标拖影（smear-cursor）

ARKVIM 自带 nvim 侧光标拖影（smear-cursor，带粒子特效），策略是**终端自带拖影/光标动画时不重复启用**：

- 启动时自动探测终端 —— 有原生动效就跳过 nvim 插件，并提示一次（提示只显示一次，之后可用 `:ArkTrail status` 查看）；
- 想强制开启/关闭，随时用命令：

| 命令 | 作用 |
|---|---|
| `:ArkTrail on` | 强制开启（会先把插件加载进来） |
| `:ArkTrail off` | 关闭 |
| `:ArkTrail toggle` | 切换（等同 `<space>us`） |
| `:ArkTrail status` | 查看终端 / 插件 / 拖影状态 |

#### 自动探测的终端

| 终端 | 原生动效开关 | 说明 |
|---|---|---|
| **kitty** | `cursor_trail` > 0 | 读 `~/.config/kitty/kitty.conf`（含 `include`） |
| **konsole** | `AnimatingCursorEnabled` | 读默认 profile 的 `[Terminal Features]`（`konsolerc` 的 `DefaultProfile`，或 `KONSOLE_PROFILE_NAME`）；源码默认 `false` |
| foot / alacritty | 无此功能 | 探测到但不跳过，插件正常启用 |
| 其他终端 | — | 用下面的覆盖开关 |

加新终端：在 `lua/arkvim/terminal.lua` 的 `TRAIL_PROBES` 里追加一条 `{ name, match, get }` 即可。

#### 覆盖（探测不到 / 想强制）

```lua
-- init.lua
vim.g.arkvim_native_cursor_trail = true   -- 我有原生拖影，别启插件
vim.g.arkvim_native_cursor_trail = false  -- 反过来：强制启用插件
```

或启动时带环境变量：`ARKVIM_NATIVE_CURSOR_TRAIL=1 nvim`（`0/false/no` 为强制启用）。

拖影颜色/速度/粒子参数在 `lua/plugins/smooth.lua`；光标颜色统一取自 `lua/arkvim/terminal.lua` 的 `cursor_color`（kitty 会读 `cursor` 配置）。

### 一键创建框架工程（`<space>pc`）

在当前目录下创建带预设骨架的工程文件夹，**共 100 个模板 / 35 种语言**：

| 类别 | 模板 |
|---|---|
| GUI / 图形 | Qt6 Widgets、Qt6 Quick/QML、GTK4、gtkmm3、wxWidgets、SDL3、raylib、GLFW+Dear ImGui、JavaFX、Swing、PySide6、Tkinter、Gradio、egui、Compose Multiplatform |
| Java/Kotlin | Spring Boot、Quarkus、Micronaut、Java CLI、Android、Ktor |
| C/C++ | CMake (C)、CMake (C++17) |
| Go | module、Gin、Fiber、Echo、Chi |
| Rust | Cargo、Actix、Axum、Rocket、Leptos、Bevy、Tauri |
| Python | package、FastAPI、FastAPI+SQLAlchemy+Alembic、Django、Flask、Typer、argparse、**爬虫（requests+bs4 / Scrapy / Playwright / httpx+parsel）**、pytest、pandas、Streamlit、Celery |
| Web/TS | Node、Express、Hono、React、Next.js、Vue、Nuxt、Angular、SvelteKit、Astro、SolidJS、Remix、Electron、React Native |
| 系统语言 | Zig、Nim、Crystal、D、Julia、Swift、C#/.NET |
| 少见语言 | **Haskell**、OCaml、**Common Lisp**、Scheme、Racket、Erlang、Elixir、Phoenix、Clojure、Scala、Perl |
| 脚本/其他 | LÖVE、**Neovim 插件模板**、Bash、Nix flake、Solidity (Foundry)、Rails、Sinatra、Symfony、Laravel、Flutter、Dart |
| DevOps | Docker Compose (nginx+PG)、Compose 基础设施 (PG+Redis) |

**依赖提示**：每个模板声明了所需依赖（二进制 / pacman / pip / npm）。生成时若缺少依赖，会用**原生通知**提示安装命令（不阻塞生成），选择窗口里也会显示 `⚠ 缺依赖`。

生成后会自动跳进项目目录（`cd`）并打开工程主文件。

实现见 `lua/arkvim/scaffold/`（`util.lua` 工具 + `init.lua` 注册表/选择窗口 + 各语言模块），添加新模板只需新建/修改对应语言文件里的 `M.frameworks`。

### DevOps（Docker / Compose）

- `dockerls`、`docker-compose-language-service` LSP 补全 + hadolint 检查（写 Dockerfile / compose 即用）
- Dockerfile / YAML 语法高亮
- 快捷键（自动定位工程内最近的 compose 文件，底部终端执行）：

| 快捷键 | 动作 |
|---|---|
| `<space>Dp` | docker compose ps |
| `<space>Du` | docker compose up -d --build |
| `<space>Dd` | docker compose down |
| `<space>Db` | docker compose build |
| `<space>Dl` | docker compose logs -f |
| `<space>Dx` | docker compose exec（询问 service / command） |
| `<space>Ds` | docker ps -a |
| `<space>Di` | docker images |

## 其它新增插件

| 插件 | 说明 |
|---|---|
| [oil.nvim](https://github.com/stevearc/oil.nvim) | 类 vim-vinegar 文件管理，目录可直接当缓冲区编辑 |
| [duplicate.nvim](https://github.com/hinell/duplicate.nvim) | 复制行 / 选区 / 文本对象 |
| [vim-visual-multi](https://github.com/mg979/vim-visual-multi) | 多光标编辑 |
| [emmet-vim](https://github.com/mattn/emmet-vim) | HTML / CSS 缩写展开（输入模式按 `<C-y>,`） |
| [nvim-colorizer.lua](https://github.com/NvChad/nvim-colorizer.lua) | CSS / HTML 颜色实时预览 |
| [noice.nvim](https://github.com/folke/noice.nvim) | 命令栏 / 消息 / LSP 进度 UI 美化（不影响启动页 ASCII 艺术字） |

## fd（文件树搜索）

`<space>e` 文件树内输入 `/` 进行搜索依赖 `fd`。若系统中缺失 `fd`：

- 配置会在启动后（VeryLazy，不占启动时间）自动检测，缺失时自动把官方静态二进制安装到
  `~/.local/share/nvim/arkvim/bin`，无需 sudo；
- 也可手动安装：Arch `sudo pacman -S fd`、Debian/Ubuntu `sudo apt install fd-find`（并软链 `fdfind`→`fd`）。

## 兼容性

- **Linux**：完全支持。通过 `TERM_PROGRAM` / 父进程检测当前终端类型，自动开同类型新窗口。支持 kitty、alacritty、wezterm、foot、gnome-terminal、konsole、xfce4-terminal、lxterminal、urxvt、st、terminator、tilix、xterm、tmux、screen 等。检测不到时 fallback 按已知终端逐个尝试。
- **macOS**：支持。检测 iTerm2 / Apple Terminal，通过 `.command` 临时脚本开同类型新窗口。`<space>fT` 和 `<space>k` 均可正常工作。
- **Windows**：支持。检测 Windows Terminal (wt)、PowerShell、cmd、Git Bash，自动在同类型终端中打开新窗口。

## 配置结构

```
~/.config/nvim/
  init.lua                    入口
  lazy-lock.json              插件版本锁定
  lazyvim.json                 LazyVim 扩展配置
  stylua.toml                  Lua 格式化配置
  lua/
    config/
      lazy.lua                lazy.nvim 引导 + 语言扩展 + VeryLazy 延迟 setup
      keymaps.lua             快捷键
      options.lua             选项
      autocmds.lua            自动命令
      tty-theme.lua           TTY 磷光绿配色
    arkvim/                   ARKVIM 自有功能模块
      project.lua             统一项目检测（marker + glob，20+ 语言）
      build.lua               构建/运行/测试/清理 + watch 模式
      scaffold/               一键创建框架工程
        init.lua                注册表 + 选择窗口 + 生成入口
        util.lua                模板工具 + 依赖检查（原生通知）
        java/kotlin/cpp/go/rust/python/ruby/php/dart/
        web/systems/scripting/devops.lua   各语言模板
      capabilities.lua        能力注册表（项目检测 → 自动加载 / 提示）
      hints.lua               一次性提示 + 能力面板（<space>Xh）
      terminal.lua            终端探测（背景色 / 光标色 / 是否自带拖影）
      smear.lua               光标拖影开关（:ArkTrail on/off/toggle/status）
      watcher.lua             外部修改监听（fs_event + checktime）
      git.lua                 gh 一键操作（<space>G*）
      mobile.lua              Flutter / Android / molten 辅助
      preview.lua / modules.lua / api.lua / devops.lua / deps.lua
      cava-theme.lua          cava 渐变配色读取
      tactical.lua            战术终端（foot/alacritty）极简 UI
      header.sh / header-tactical.sh   启动页艺术字
    plugins/                  lazy.nvim 插件 spec（含各语言/工具集成）
```

## 性能

启动时间约 **35ms**（`nvim --startuptime`），主要优化手段：

- 所有插件懒加载（`lazy = true` + 事件/ft/keys 触发），启动时只加载必要项
- `arkvim.*` 里只注册键位的模块延迟到 `VeryLazy`
- markdown 相关插件按 `ft` 懒加载，不在启动时加载
- molten 的 rplugin manifest 不在启动时加载，首次用 `<space>ji` 时按需注册
- mini.icons 由 oil 按需加载（不声明为启动依赖）
- 终端探测（kitty 配置等）结果缓存，只读一次

## 主题

默认使用 tokyonight（night 风格）主题，背景透明。仪表盘显示 ARKVIM 渐变 ASCII 艺术字，颜色取自 cava 配置文件（`~/.config/cava/`）中的配色，若无 cava 则回退 tokyonight 配色。

## 鸣谢

- [LazyVim](https://github.com/LazyVim/LazyVim)
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
