-- Docker / Docker Compose language support
-- LazyVim docker extra: dockerls + docker_compose_language_service + hadolint
-- Quick Docker actions (<leader>D*) live in config/keymaps.lua -> arkvim/devops.lua
local has_docker = vim.fn.executable("docker") == 1
local has_compose = vim.fn.executable("docker-compose") == 1

return {
  {
    import = "lazyvim.plugins.extras.lang.docker",
    enabled = has_docker or has_compose,
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
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "dockerfile", "yaml" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
