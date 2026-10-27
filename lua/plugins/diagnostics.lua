-- 实时诊断显示：输入时也更新（LSP），并让浮窗/虚拟文本更清晰。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = true,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
          header = "",
        },
      },
    },
  },
}
