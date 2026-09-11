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

C、C++、Rust、Python、Java、JavaScript、TypeScript、HTML、CSS、Dockerfile / Compose、Ruby、Lua

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
| `<space>pc` | **一键创建框架工程**（选语言 → 选模板 → 输入项目名） |
| `<space>yd` | duplicate.nvim 复制当前行 / 选区 |
| `<C-n>` | vim-visual-multi 多光标：选中后逐次 `<C-n>` 添加下一个匹配 |
| `<space>D…` | Docker / Compose 快捷操作（见下方 DevOps） |

### 一键创建框架工程（`<space>pc`）

在当前目录下创建带预设骨架的工程文件夹：

| 语言 | 模板 |
|---|---|
| Java | Spring Boot（联网 start.spring.io，离线自动回退最小骨架）、Plain Java |
| C | CMake 工程 |
| C++ | CMake 工程（C++17） |
| Go | go module |
| Rust | cargo binary |
| Python | package、FastAPI |
| DevOps | Docker Compose 栈 |

生成后会自动跳进项目目录（`cd`）并打开工程主文件。

实现见 `lua/arkvim/scaffold.lua`，添加新模板只需在其 `langs[]` 中注册一个 `gen` 函数。

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
- **Windows**：未经测试。

## 配置结构

```
~/.config/nvim/
  init.lua                    入口
  lazy-lock.json              插件版本锁定
  lazyvim.json                 LazyVim 扩展配置
  stylua.toml                  Lua 格式化配置
  lua/
    config/
      lazy.lua                lazy.nvim 引导 + 语言扩展（按工具链条件加载）
      keymaps.lua             快捷键
      options.lua             选项
      autocmds.lua            自动命令
    plugins/
      arkvim.lua              tokyonight 主题（透明背景）+ 仪表盘 ARKVIM 艺术字
      c.lua                   C 语言支持
      docker.lua              Docker / Compose 语言支持 + DevOps 快捷键
      duplicate.lua           duplicate.nvim（复制行 / 选区）
      go.lua                  Go 语言支持
      html.lua                HTML / CSS 编辑增强（emmet、颜色预览）
      java.lua                Java 语言支持
      javascript.lua          JavaScript / TypeScript 支持
      lua.lua                 Lua 语言支持
      noice.lua               noice.nvim UI 美化
      oil.lua                 oil.nvim 文件管理
      python.lua              Python 语言支持
      ruby.lua                Ruby 语言支持
      rust.lua                Rust 语言支持
      visual-multi.lua        vim-visual-multi 多光标
      web.lua                 HTML / CSS LSP 支持
    arkvim/
      header.sh               ARKVIM 渐变艺术字渲染脚本（支持 cava 配色）
      scaffold.lua            一键创建框架工程（Spring Boot / CMake / go / cargo / Python / Docker …）
      deps.lua                fd 等外部依赖检测与自动安装
      tactical.lua            战术终端（foot/alacritty）极简 UI
```

## 主题

默认使用 tokyonight（night 风格）主题，背景透明。仪表盘显示 ARKVIM 渐变 ASCII 艺术字，颜色取自 cava 配置文件（`~/.config/cava/`）中的配色，若无 cava 则回退 tokyonight 配色。

## 鸣谢

- [LazyVim](https://github.com/LazyVim/LazyVim)
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
