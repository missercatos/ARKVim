-- Docker / Compose language support
-- The `lazyvim.plugins.extras.lang.docker` extra (dockerls + compose LS + hadolint)
-- is imported from config/lazy.lua (kept in correct import order).
-- Here we only add what the extra does not cover.
local has_docker = vim.fn.executable("docker") == 1
local has_compose = vim.fn.executable("docker-compose") == 1

return {
  {
    -- yaml parser for compose files (dockerfile parser is added by the docker extra)
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "yaml" })
    end,
  },
  {
    "mason-org/mason.nvim",
    enabled = has_docker or has_compose,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "dockerfile-language-server",
        "docker-compose-language-service",
        "hadolint",
      })
    end,
  },
}
