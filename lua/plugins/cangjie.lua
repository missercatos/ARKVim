-- 仓颉（Cangjie）语言支持：LSP + treesitter
--
-- 检测/补全/跳转/hover/诊断：ide4cj/cangjie.nvim（cjls 语言服务器）。
-- cjls 是静态二进制，首次打开 .cj 时自动下载；不需要额外安装 SDK
-- （但做 std 分析/编译运行需要 Cangjie SDK，见 cangjie 命令）。
--
-- 注意：插件当前 pin 的 cjls 是 v0.5.0，补全/跳转是 v0.6.0 才加入的，
-- 所以这里显式指定 v0.6.0。
return {
  {
    "ide4cj/cangjie.nvim",
    lazy = false, -- 让它 plugin/ 里的 parser 注册在 nvim-treesitter 安装前生效
    init = function()
      vim.g.cjls_version = "v0.6.0"

      local sdk = vim.fn.expand("~/.local/share/cangjie/current/cangjie")
      local wrappers = vim.fn.expand("~/.local/share/cangjie/wrappers")
      local cjls_bin = vim.fn.stdpath("data") .. "/cjls/bin"
      local arch = (vim.uv or vim.loop).os_uname().machine
      -- 即使 nvim 不是从 fish 启动、PATH 里没有 cjpm/cjc，cjls 也能找到 SDK；
      -- LD_LIBRARY_PATH 只给 cjls 及其子进程（不污染全局）。
      vim.lsp.config("cjls", {
        cmd_env = {
          CANGJIE_HOME = sdk,
          PATH = wrappers .. ":" .. cjls_bin .. ":" .. (vim.env.PATH or ""),
          LD_LIBRARY_PATH = string.format("%s/runtime/lib/linux_%s_cjnative:%s/tools/lib", sdk, arch, sdk),
        },
        settings = {
          cjls = {
            cangjieHome = sdk,
          },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "cangjie" })
    end,
  },
}
