local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
}

if vim.fn.executable("clangd") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.clangd" })
end
if vim.fn.executable("rustc") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.rust" })
end
if vim.fn.executable("python3") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.python" })
end
if vim.fn.executable("node") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.typescript" })
end
if vim.fn.executable("java") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.java" })
end
if vim.fn.executable("go") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.go" })
end
if vim.fn.executable("ruby") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.ruby" })
end
if vim.fn.executable("docker") == 1 or vim.fn.executable("docker-compose") == 1 then
  table.insert(spec, { import = "lazyvim.plugins.extras.lang.docker" })
end

table.insert(spec, { import = "lazyvim.plugins.extras.dap.core" })
table.insert(spec, { import = "lazyvim.plugins.extras.test.core" })

table.insert(spec, { import = "plugins" })

-- 早期 setup：依赖首个 buffer 的 BufEnter/BufReadPost 检测，必须尽早注册
require("arkvim.watcher").setup()
require("arkvim.hints").setup() -- 内部会 require arkvim.project + arkvim.capabilities

-- 仅注册键位的模块延迟到 VeryLazy，省启动时间（VeryLazy 紧随启动后触发）
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("arkvim.build").setup()
    require("arkvim.preview").setup()
    require("arkvim.modules").setup()
    require("arkvim.api").setup()
    require("arkvim.git").setup()
  end,
})

require("lazy").setup({
  spec = spec,
  defaults = {
    lazy = true,
    version = false,
  },
  install = { colorscheme = { "tokyonight" } },
  checker = {
    enabled = true,
    notify = false,
  },
    performance = {
      cache = {
        enabled = true,
      },
      rtp = {
        disabled_plugins = {
          "gzip",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
          "netrwPlugin", -- oil takes over directory editing
        },
      },
    },
})
