# ARKVim 的 home-manager 模块
#
# 用法（在你的 home-manager 配置里）：
#   {
#     imports = [ arkvim.homeManagerModules.default ];
#     programs.arkvim.enable = true;
#   }
#
# NixOS 上更简单：用 arkvim.nixosModules.default（见 nix/README.md）。
{ src }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.arkvim;
in
{
  options.programs.arkvim = {
    enable = lib.mkEnableOption "ARKVim Neovim 配置";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "使用的 neovim 包（可换成 neovim-unwrapped 包装版）";
    };

    installTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "安装 ARKVim 需要的外部工具（LSP / 格式化 / 各语言运行时）";
    };

    deployConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "把本仓库配置部署到 ~/.config/nvim";
    };

    deployMode = lib.mkOption {
      type = lib.types.enum [ "symlink" "copy" ];
      default = "symlink";
      description = ''
        部署方式：
        - symlink（默认）：软链到 nix store，只读。`:Lazy sync` 无法写回 lazy-lock.json。
        - copy：复制成可写目录（lazy.nvim 能正常更新锁文件），每次 switch 会覆盖。
      '';
    };

    disableMason = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        设置 ARKVIM_NO_MASON=1：LSP / 格式化全部走 Nix 提供的二进制，
        关掉 Mason，避免它在 NixOS 上下载无法执行的通用二进制并抢占 PATH。
        （关掉后 Mason 不再提供 DAP 适配器，需要的话自己配 dap.adapters 或用 Nix 包。）
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      package = cfg.package;
      withPython3 = true; # molten / pynvim
      withNodeJs = true; # copilot 等
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    home.packages = lib.optionals cfg.installTools (import ./tools.nix { inherit pkgs; });

    home.sessionVariables = lib.mkIf cfg.disableMason {
      ARKVIM_NO_MASON = "1";
    };

    # 部署配置
    xdg.configFile = lib.mkIf (cfg.deployConfig && cfg.deployMode == "symlink") {
      "nvim".source = src;
    };

    home.activation = lib.mkIf (cfg.deployConfig && cfg.deployMode == "copy") {
      arkvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run rm -rf "$HOME/.config/nvim"
        run mkdir -p "$HOME/.config/nvim"
        run cp -r ${src}/. "$HOME/.config/nvim/"
        run chmod -R u+w "$HOME/.config/nvim"
      '';
    };
  };
}
