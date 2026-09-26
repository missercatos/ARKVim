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

### NixOS / home-manager 一键复现

仓库自带 `flake.nix`：把配置、neovim 和全套 LSP/工具链一起装好。

```bash
# NixOS：在你的 flake 里 import 本仓库的模块
#   modules = [ arkvim.nixosModules.default { programs.arkvim.users = [ "你的用户名" ]; } ];
sudo nixos-rebuild switch --flake /etc/nixos#myhost

# 已有 home-manager：
#   imports = [ arkvim.homeManagerModules.default ];  programs.arkvim.enable = true;
home-manager switch --flake .#me

# 只想试一下（不改系统）
nix develop github:missercatos/ARKVim     # 带全套工具的 shell
nix run     github:missercatos/ARKVim     # 直接跑 nvim
```

细节（选项、Mason 处理、symlink/copy 部署方式）见 [`nix/README.md`](nix/README.md)。

### Windows 一键安装

三种方式，任选其一（装完 `nvim` 会进用户 PATH，所有 Windows 终端可用）：

```powershell
# 1) 一行命令（推荐）
irm https://raw.githubusercontent.com/missercatos/ARKVim/master/install.ps1 | iex

# 2) 下载 install.exe 双击（Releases 里，CI 自动构建）

# 3) 下载仓库后双击 install.cmd，或：
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

默认装 Neovim + 配置 + ripgrep/fd + Nerd Font；`-Minimal` 只装 nvim+配置，`-Tools` 连语言工具链一起装。
细节与已知限制见 [`windows/README.md`](windows/README.md)。

## 支持的语言

C、C++、Rust、Python、Java、Kotlin、Go、JavaScript、TypeScript、HTML、CSS、Dockerfile / Compose、Ruby、Lua、Dart / Flutter、PHP、**Nix**，
以及通过 `:ArkTrail`/构建系统覆盖的 Zig、Nim、Crystal、D、Haskell、OCaml、Lisp、Scheme、Racket、Erlang、Elixir、Julia、Swift、C#、Clojure、Scala、Solidity 等（脚手架共 35 种语言 / 100 个模板）。

**Nix** 语言支持：treesitter `nix` + LSP（`nixd` 优先，其次 `nil`）+ `nixfmt`/`alejandra` 格式化 + `statix`/`deadnix` 检查，见 `lua/plugins/nix.lua`。装了 `nix`/`nixd`/`nil` 任一即自动启用。**NixOS 一键复现见 [`nix/README.md`](nix/README.md)。**

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
| `<space>pc` | **一键创建框架工程**（选语言 → 选模板 → 输入项目名，共 100 个模板；**不会改变工作目录**） |
| `<space>pu` / `<space>pE` / `<space>pw` | 目录跳转：上一级 / 进入当前项目 / 回到工作区（也可用 `:ArkCd [path\|..\|-]`） |
| `<space>Bb/Br/Bt/Bc` | 构建 / 运行 / 测试 / 清理当前项目（键位常驻；不在项目里会直接告诉你） |
| `<space>Bw` / `<space>BW` | watch 模式：保存文件自动重跑 build / test（再按一次关闭） |
| `<space>Bo` / `<space>BR` | overseer 任务面板 / 运行任务 |
| `<space>tw` / `<space>tW` / `<space>tq` | 实时测试：watch 当前文件 / 整个项目 / 停止全部（neotest 不可用时自动退回保存触发） |
| `<space>ti` | 实时测试诊断（项目/类型/LSP/适配器状态） |
| `<space>dR` 或 `:ArkDebug` | **调试整个项目**（有 DAP 配置就弹选择；没有就按项目类型以调试模式启动） |
| `<space>us` 或 `:ArkTrail` | 光标拖影开关（见下方「光标拖影」） |
| `<space>uM` | **媒体文件：渲染 ↔ 源码（字节）切换**（图片/视频/GIF/PDF） |
| `<space>Mm` / `<space>Me` | 音乐：mpv 播放器组件 / echo.nvim 音效试听 |
| `:ArkMusic …` | 音频总开关（`player` / `autoplay` / `mpv` / `echo` / `status`） |
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

生成后会自动打开工程主文件，**但不会 cd 进项目** —— 工作目录保持在工作区，所以：

- 可以在同一个工作区里**平级创建多个框架**（不会套娃），不用来回切终端；
- 左侧文件树停在工作区，能看到所有项目，想进去按 `<space>pE` 或 `:ArkCd`；
- 想回工作区按 `<space>pw`（`:ArkCd -`），上一级按 `<space>pu`（`:ArkCd ..`）。

```bash
# 典型多框架工作区
~/work/myapp/
  backend/     ← <leader>pc 选 FastAPI
  frontend/    ← <leader>pc 选 React + Vite
  mobile/      ← <leader>pc 选 Flutter
```

**文件树里上下移动**：`<BS>` 或 `-` 回上一级（`-` 与 oil 一致），`l`/回车 进入，`h` 收起目录。`u` 是"刷新"而不是"上一级"，别按错。

实现见 `lua/arkvim/scaffold/`（`util.lua` 工具 + `init.lua` 注册表/选择窗口 + 各语言模块）+ `lua/arkvim/dirs.lua`（目录跳转），添加新模板只需新建/修改对应语言文件里的 `M.frameworks`。

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

## 媒体文件（图片 / 视频 / GIF / PDF）与音频

### 渲染 ↔ 源码

图片、视频、GIF、PDF 由 `snacks.image` 直接渲染；想**看源码（二进制字节）**：

| 操作 | 说明 |
|---|---|
| `<space>uM` | 当前缓冲区：渲染 ↔ 源码 来回切 |
| `:ArkMediaRender off` | **全局**关闭渲染（之后新开的媒体文件都按普通文本读） |
| `:ArkMediaRender on` / `toggle` / `status` | 恢复 / 切换 / 查看状态 |

切到源码时会自动 **`modifiable = true`**（可直接改字节）、`binary = true`、关语法。
源码视图下 `:w` 会**弹确认**（写回就是直接改原文件），默认选"取消"。

> 原理：`snacks.image` 用 `BufReadCmd` 接管了这些格式，buffer 里**其实没有内容**且被锁成 `nomodifiable`。
> 所以只开 `modifiable` 会看到空文件；正确做法是 `:noautocmd edit!` 跳过它的 `BufReadCmd` 重新读一次字节。

### 音频 / 音乐

默认**全部关闭**，用命令开启（开启后才会注册对应快捷键）：

| 命令 | 作用 |
|---|---|
| `:ArkMusic autoplay on` | 打开音频文件自动用 **mpv** 播放，离开缓冲区停止（默认关） |
| `:ArkMusic player on` | 开启 nvim 内置本地音乐播放器（[player.nvim](https://github.com/jmatth11/player.nvim)）→ `<space>Mf` 选歌窗口 · `<space>Mp` 播放器面板 |
| `:ArkMusic mpv` / `<space>Mm` | mpv 播放器小组件（[mpv.nvim](https://github.com/tamton-aquib/mpv.nvim)） |
| `:ArkMusic echo` / `<space>Me` | 试听 [echo.nvim](https://github.com/melMass/echo.nvim) 音效（Windows / macOS 默认启用） |
| `:ArkMusic status` | 查看各开关与依赖状态（含 player.nvim 原生库是否已构建） |

依赖与首次准备：

- **mpv**：自动播放和 mpv.nvim 需要（Arch：`sudo pacman -S mpv`；Windows：`scoop install mpv`）
- **player.nvim**：需要构建原生库，装完插件后先跑一次
  ```
  :Lazy build player.nvim
  ```
  它会自动下载 Zig 并编译（首次几分钟，需联网）。没构建时 `:ArkMusic player on` 会提示而不是报错。
  仅类 Unix 有 `build.sh`，**Windows 上跳过构建，该功能不可用**。
- **echo.nvim**：需要它自己的 Rust 二进制（`melMass/echo.nvim` 的 README 说明 0.0.1 的 lazy 安装还拿不到二进制）；仅在 Windows / macOS 默认启用。
- **ambience.nvim**：GitHub 上找不到该插件，暂未接入（`:ArkMusic ambience` 会提示）。

## 项目识别：`<leader>B*` 到底作用在哪个项目

`<leader>Bb/Br/Bt/Bc`、`<leader>Bw/BW`、`<leader>dR`、实时测试都依赖「当前项目」的判断。
规则（`arkvim/project.lua`）：

1. **以当前文件所在目录为准**，不是以 nvim 的 cwd 为准。
   （以前用 cwd 找 git 根，在 `~/.config/nvim` 里打开别的项目的文件时会把项目认错，
   于是 `<leader>Bt` 要么提示「不支持当前项目类型」，要么干脆没反应。）
2. 项目根取 **git 仓库根**；如果 git 根上没有构建清单（marker），
   就用**离文件最近的子项目**（monorepo 的 `packages/web` 这类）。
   多模块 Gradle/Maven 因此会正确地在仓库根跑（`./gradlew`、`./mvnw`）。
3. 没有 git 时用最近的 marker 目录；什么 marker 都没有 → 提示「未检测到项目」。
4. `<leader>B*` 键位**始终注册**，按了没反应会明确告诉你原因（项目类型不支持 / 未检测到项目）。

## 调试 / 实时测试（含框架项目）

LazyVim 只为 java/go/python/ruby/rust/c/cpp/js/ts 提供了 DAP 配置，
**Kotlin、Android、Gradle 这类框架项目 `<leader>dc` 会直接报 "No configurations found"**。
这里补了一层：

### `<leader>dR` / `:ArkDebug`　调试整个项目

| 情况 | 行为 |
|---|---|
| 当前文件类型**有** DAP 配置（Java/Python/Go/Rust/Node…） | 走 `dap.continue()`，弹出配置选择（等同 `<leader>dc`） |
| **没有**配置（Kotlin/Android/Dart…） | 按项目类型用「带调试端口启动」的命令在终端里跑 |

`arkvim/dap.lua` 会：
- 把 LazyVim 的 **java 配置复制给 kotlin**（同一个 JVM 调试器）
- 补一个通用 **`Attach to JVM (port 5005)`** 配置，配 `:ArkDebug attach` 连接

按项目类型的内置调试启动（`arkvim/build.lua`）：

| 项目 | 调试启动命令 |
|---|---|
| Maven / Spring Boot | `mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=…address=*:5005"` |
| Gradle / Spring | `./gradlew bootRun --debug-jvm`（挂在 5005 等 attach） |
| Gradle / Android | `./gradlew installDebug`（装到设备） |
| Gradle / 普通 JVM | `./gradlew run --debug-jvm` |
| Java CLI | `java -agentlib:jdwp=…,suspend=y,address=5005 -cp out <Main>` |
| Go / Node / Python | `dlv debug .` / `NODE_OPTIONS=--inspect npm run dev` / debugpy |

> Gradle task 是自动识别的（读根目录 + `app/` + version catalog），
> 因为很多项目用 `alias(libs.plugins.android.application)` 或 convention plugin，
> 不能只搜 `com.android.application`。

### 实时测试

常用三个键：

| 键 | 行为 |
|---|---|
| `<space>tw` | neotest watch 当前文件 |
| `<space>tW` | neotest watch 整个项目 |
| `<space>tq` | 停止所有 watch |
| `<space>ti` | 诊断：项目 / 文件类型 / LSP / 适配器 / 能否 watch |

**neotest 的 watch 需要两件事**：该语言有 neotest adapter + 有 LSP client 附加。
框架项目常常不满足（Kotlin/Android 没有 neotest adapter），这时会**自动退回**
`arkvim.build` 的「保存触发测试」（和 `<space>BW` 同一套，不依赖 LSP 和 adapter），
并给一条提示说明为什么退回。

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
      dirs.lua                目录跳转（:ArkCd / <space>pu·pE·pw / 工作区记录）
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
