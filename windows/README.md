# ARKVim on Windows

在 Windows 上装好 Neovim + ARKVim 配置，并把 `nvim` 加进**用户 PATH**，
这样 cmd / PowerShell / Windows Terminal / Git Bash 里都能直接敲 `nvim`。

## 三种安装方式

### 1. 一行命令（推荐）

```powershell
irm https://raw.githubusercontent.com/missercatos/ARKVim/master/install.ps1 | iex
```

### 2. `install.exe`（双击即装）

从 [Releases](https://github.com/missercatos/ARKVim/releases) 下载 `install.exe` 双击运行
（由 GitHub Actions 用 PS2EXE 自动构建）。

> 未签名 → 首次运行 SmartScreen 会拦一下：**更多信息 → 仍要运行**。

### 3. `install.cmd` / 本地脚本

下载仓库后，双击 `install.cmd`，或：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## 参数

| 参数 | 说明 |
|---|---|
| `-Minimal` | 只装 Neovim + 配置（不装 ripgrep/fd/字体） |
| `-Tools` | 额外装语言运行时与 LSP（node/python/go/rust/jdk/clang/cmake/ninja/docker，耗时较长） |
| `-NoFont` | 不装 Nerd Font |
| `-Dir <路径>` | 配置目录，默认 `%LOCALAPPDATA%\nvim` |
| `-Branch <分支>` | 默认 `master` |
| `-Yes` | 不再询问确认 |

```powershell
# 只装最小
irm https://raw.githubusercontent.com/missercatos/ARKVim/master/install.ps1 | iex
# 想带工具链就本地跑：
.\install.ps1 -Tools
```

## 装了什么

| 项 | 说明 |
|---|---|
| Neovim | 优先 `winget install Neovim.Neovim`；没有 winget 就下官方 `nvim-win64.zip` 便携版 |
| PATH | 把 nvim 所在目录写进**用户 PATH**（所有终端生效） |
| 配置 | `git clone` 到 `%LOCALAPPDATA%\nvim`（已存在同名目录会先备份成 `.bak-<时间戳>`） |
| ripgrep / fd | 文件树搜索与 picker 依赖（`-Minimal` 跳过） |
| Nerd Font | JetBrainsMono Nerd Font，装到用户字体目录（`-NoFont` 跳过） |
| 插件 | 跑一次 `nvim --headless "+Lazy! sync" +qa` 预装（失败不影响首次启动自动装） |

装完**重开一个终端**，运行 `nvim`。进去后可 `:checkhealth` 体检。

## 卸载

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim"        # 配置
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data"   # 插件 / 数据
winget uninstall Neovim.Neovim                              # 本体（便携版则删目录）
```

## 终端字体

Windows Terminal：**设置 → 配置文件 → 外观 → 字体 → `JetBrainsMono Nerd Font`**
（不设的话图标会显示成方块）。

## 已知限制（配置是 Linux 优先写的）

| 功能 | Windows 表现 |
|---|---|
| 战术绿色主题 / `tactical` | ❌ 不启用（仅 foot/alacritty） |
| 文件树、picker、LSP、补全、git、脚手架 | ✅ 正常 |
| 光标拖影 `smear` | ✅ 正常（Windows 终端没有原生拖影，插件会自动启用；`:ArkTrail` 可开关） |
| `<leader>k` 编译运行 | ✅ 用 `cmd /c`，C/C++/Rust 会生成 `.exe` |
| `<leader>K` 外部窗口编译运行 | ✅ 新开 cmd 窗口 |
| `<leader>pp` 预览 | ⚠️ 前端项目（`npm run dev` 等）走 PowerShell 可以跑；HTML 直接用系统默认程序打开；niri/hyprctl 分支在 Windows 上不会触发 |
| `<leader>B*` 构建/运行/测试 | ⚠️ 命令按 Windows 转成 PowerShell（`rm -rf` 等常见命令已替换）；个别框架的 Unix 专属命令可能失败 |
| 脚手架 `<leader>pc` | ⚠️ 生成没问题；个别模板的联网/解压步骤依赖 `curl`/`unzip`/`cp`，缺失时会走离线骨架 |

> 一句话：**日常写代码完全够用**（编辑/LSP/补全/git/文件树/拖影），
> Linux 专属的窗口管理和部分构建脚本在 Windows 上是降级或不可用。

## 手动安装（不用脚本）

```powershell
winget install Neovim.Neovim
git clone https://github.com/missercatos/ARKVim.git "$env:LOCALAPPDATA\nvim"
# 把 nvim 目录加进 PATH，然后：
nvim
```

配置文件位置与 Linux 不同：

| | 路径 |
|---|---|
| 配置 | `%LOCALAPPDATA%\nvim` |
| 数据/插件 | `%LOCALAPPDATA%\nvim-data` |
| 状态（提示/项目记录） | `%LOCALAPPDATA%\nvim-data\...`（`stdpath('state')`） |
