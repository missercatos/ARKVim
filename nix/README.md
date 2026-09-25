# ARKVim on Nix / NixOS

在 NixOS（或任何装了 Nix 的机器）上一键复现这套 Neovim 配置。

> ⚠️ 这些 Nix 文件是在 Arch 机器上写的、**未经 `nix flake check` 验证**。
> 首次使用请先跑一次 `nix flake check` 或 `nix develop`，按提示删掉本机
> nixpkgs 里不存在的包（`nix/tools.nix` 已做安全跳过，一般不会报错）。

## 三种用法

### 1. NixOS 一键复现（推荐）

在你的 NixOS flake（`/etc/nixos/flake.nix`）里加：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    arkvim.url = "github:missercatos/ARKVim";
  };

  outputs = { nixpkgs, arkvim, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        arkvim.nixosModules.default
        ./configuration.nix
        { programs.arkvim.users = [ "你的用户名" ]; }
      ];
    };
  };
}
```

```bash
sudo nixos-rebuild switch --flake /etc/nixos#myhost
```

### 2. 已有 home-manager（非 NixOS 也行）

```nix
{
  inputs.arkvim.url = "github:missercatos/ARKVim";

  outputs = { home-manager, arkvim, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      modules = [
        arkvim.homeManagerModules.default
        { programs.arkvim.enable = true; }
      ];
    };
  };
}
```

```bash
home-manager switch --flake .#me
```

### 3. 只想试一下（不改系统）

```bash
# 带全套工具的临时 shell
nix develop github:missercatos/ARKVim

# 带全套工具直接跑 nvim
nix run github:missercatos/ARKVim
```

## 选项（`programs.arkvim.*`）

| 选项 | 默认 | 说明 |
|---|---|---|
| `enable` | `false` | 总开关 |
| `package` | `pkgs.neovim` | 换 neovim 包（例如自建 wrapper） |
| `installTools` | `true` | 安装 LSP / 格式化 / 各语言运行时（清单见 `tools.nix`） |
| `deployConfig` | `true` | 把本仓库部署到 `~/.config/nvim` |
| `deployMode` | `"symlink"` | `symlink`（只读，`:Lazy sync` 写不了锁文件）/ `copy`（可写副本，switch 时覆盖） |
| `disableMason` | `true` | 设 `ARKVIM_NO_MASON=1`，LSP 全走 Nix，关掉 Mason |

## 为什么默认关 Mason？

Mason 下载的是通用 glibc 预编译二进制，在 NixOS 上**无法执行**（找不到 `/lib64/ld-linux-x86-64.so.2`），
而且 `mason.nvim` 会把 `~/.local/share/nvim/mason/bin` **前置**到 `PATH`，把 Nix 提供的正常二进制挤掉。

设了 `ARKVIM_NO_MASON=1` 后：

- `plugins/mason-nix.lua` 把 mason / mason-lspconfig / mason-nvim-dap 全部 `enabled = false`
- LazyVim 检测不到 mason-lspconfig 时，会直接 `vim.lsp.enable(server)`，用 `PATH` 上的二进制
- 代价：Mason 不再提供 DAP 适配器（codelldb / debugpy）。需要调试的话，用 Nix 装并在
  `dap.adapters` 里手动指定路径，或者别设这个变量。

## 配置部署方式怎么选？

| | `symlink`（默认） | `copy` |
|---|---|---|
| 磁盘 | 软链，零拷贝 | 复制一份 |
| 可写 | ❌（nix store 只读） | ✅ |
| `:Lazy sync` 更新 `lazy-lock.json` | 写不进去（会有提示） | 正常 |
| 改配置 | 改仓库 → `nixos-rebuild switch` | 同上（switch 会覆盖运行时改动） |

大多数 Nix nvim 配置用 `symlink`；如果你经常 `:Lazy update`，用 `copy`。

## 手动装（不想用模块）

```bash
git clone https://github.com/missercatos/ARKVim ~/.config/nvim
nix develop ~/.config/nvim        # 或在 configuration.nix 里 environment.systemPackages
```

然后照常启动 `nvim` 让 lazy.nvim 装插件。
