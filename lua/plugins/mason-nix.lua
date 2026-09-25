-- NixOS 适配：LSP / 格式化 / 检查工具全部由 Nix 提供。
--
-- 为什么要处理 Mason：
--   1) Mason 下载的是通用 glibc 预编译二进制，在 NixOS 上执行不了
--      （找不到 /lib64/ld-linux-x86-64.so.2）
--   2) mason.nvim 会把 ~/.local/share/nvim/mason/bin **前置**到 PATH，
--      把 Nix 提供的正常二进制挤掉
--
-- 触发：环境变量 ARKVIM_NO_MASON=1（nix/module.nix 会自动设置）
--
-- 做法（比 enabled=false 可靠：enabled 挡不住依赖链）：
--   - PATH = "skip"  → Mason 不再改 PATH，Nix 的二进制优先
--   - 覆盖 config    → 跳过 ensure_installed 的自动安装
--   - 语言 extra 里给每个 server 的 `mason = false` 已在 plugins/*.lua 里写死，
--     LazyVim 会把它们直接 vim.lsp.enable()，走 PATH
if vim.env.ARKVIM_NO_MASON ~= "1" then
  return {}
end

return {
  {
    "mason-org/mason.nvim",
    opts = { PATH = "skip" },
    config = function(_, opts)
      -- 忽略各语言 extra 追加的 ensure_installed，别去下载
      opts.ensure_installed = {}
      opts.PATH = "skip"
      require("mason").setup(opts)
    end,
  },
  { "mason-org/mason-lspconfig.nvim", optional = true, opts = { ensure_installed = {} } },
  { "jay-babu/mason-nvim-dap.nvim", optional = true, opts = { ensure_installed = {} } },
}
