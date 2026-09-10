-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Make sure `fd` (needed by the <space>e explorer search) is available
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("arkvim.deps").check_all()
  end,
})

-- Auto-append file extension when creating a new file in a scaffolded project.
-- Triggered by <space>a (keymaps.lua) or any :e newfile without extension.
local lang_ext = {
  java = "java", python = "py", rust = "rs", go = "go",
  c = "c", cpp = "cpp", devops = "yml",
}

vim.api.nvim_create_autocmd("BufNewFile", {
  callback = function(args)
    local lang = vim.g.arkvim_project_lang
    if not lang then
      return
    end
    local ext = lang_ext[lang]
    if not ext then
      return
    end
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" then
      return
    end
    -- Only if file has no extension
    if vim.fn.fnamemodify(path, ":e") ~= "" then
      return
    end
    local new_name = path .. "." .. ext
    vim.api.nvim_buf_set_name(args.buf, new_name)
    -- Save to disk so the file tree reflects the correct name
    vim.cmd("silent write! " .. vim.fn.fnameescape(new_name))
    vim.notify("已自动添加后缀: " .. ext, vim.log.levels.INFO)
  end,
})

