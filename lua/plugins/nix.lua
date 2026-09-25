-- Nix 语言支持：treesitter + LSP + 格式化 + lint
-- LSP 优先级：nixd（flake / NixOS 选项补全更强）> nil
-- 两者都由系统/Nix 提供，所以显式 `mason = false`，避免 Mason 重复下载。
local has_nixd = vim.fn.executable("nixd") == 1

-- 格式化器：nixfmt 优先，其次 alejandra
local formatter = "nixfmt"
if vim.fn.executable("nixfmt") ~= 1 and vim.fn.executable("alejandra") == 1 then
  formatter = "alejandra"
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "nix" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = { enabled = has_nixd, mason = false },
        nil_ls = { enabled = not has_nixd, mason = false },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { formatter },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        nix = { "statix", "deadnix" },
      },
    },
  },
}
