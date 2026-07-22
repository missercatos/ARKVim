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

C、C++、Rust、Python、Java、JavaScript、TypeScript、HTML、CSS、Ruby、Lua

每种语言自动配置以下功能（前提是系统中已安装对应工具链）：

| 功能 | 工具 |
|---|---|
| 智能补全（LSP） | clangd / rust-analyzer / basedpyright / ts_ls / jdtls / solargraph / lua_ls / ... |
| 自动格式化 | clang-format / rustfmt / ruff / prettier / stylua / rubocop / ... |
| 代码检查 | clang-tidy / clippy / ruff / mypy / eslint / luacheck / ... |
| 调试 | codelldb / debugpy / ... |

## 快捷键

| 快捷键 | 功能 |
|---|---|
| `<space>ft` | 内置底部终端 |
| `<space>fT` | 外部终端窗口（自动检测终端模拟器） |
| `<space>k` | 编译并运行当前文件（外部终端） |

## 兼容性

- **Linux**：完全支持。自动检测 gnome-terminal、konsole、alacritty、kitty、wezterm、xfce4-terminal、lxterminal、foot、urxvt、st、terminator、tilix、xterm 等终端模拟器。
- **macOS**：支持。外部终端通过 `.command` 临时脚本由 Terminal.app 打开并执行。`<space>fT` 和 `<space>k` 均可正常工作。
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
      java.lua                Java 语言支持
      javascript.lua          JavaScript / TypeScript 支持
      lua.lua                 Lua 语言支持
      python.lua              Python 语言支持
      ruby.lua                Ruby 语言支持
      rust.lua                Rust 语言支持
      web.lua                 HTML / CSS 支持
    arkvim/
      header.sh               ARKVIM 渐变艺术字渲染脚本（支持 cava 配色）
```

## 主题

默认使用 tokyonight（night 风格）主题，背景透明。仪表盘显示 ARKVIM 渐变 ASCII 艺术字，颜色取自 cava 配置文件（`~/.config/cava/`）中的配色，若无 cava 则回退 tokyonight 配色。

## 鸣谢

- [LazyVim](https://github.com/LazyVim/LazyVim)
- [tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
