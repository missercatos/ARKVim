-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete is available as <space>fd (File → Delete) only.
-- The bare `d` default is removed so it cannot be triggered by accident
-- while the global <space>d (debug/DAP) prefix is also active.
-- `a` is overridden to auto-append the project language extension.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["<leader>fd"] = "explorer_del",
                  ["d"] = false,
                  -- Override `a` to be project-language-aware
                  ["a"] = function(picker)
                    local lang = vim.g.arkvim_project_lang
                    local lang_ext = {
                      java = "java", python = "py", rust = "rs", go = "go",
                      c = "c", cpp = "cpp", devops = "yml",
                    }
                    local name = vim.fn.input("新建文件名: ")
                    if name == "" then
                      return
                    end
                    if lang and vim.fn.fnamemodify(name, ":e") == "" then
                      local ext = lang_ext[lang]
                      if ext then
                        name = name .. "." .. ext
                      end
                    end
                    local dir = picker and picker.cwd or vim.fn.getcwd()
                    local path = dir .. "/" .. name
                    if vim.fn.filereadable(path) == 1 then
                      vim.cmd("edit " .. vim.fn.fnameescape(path))
                    else
                      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                      vim.cmd("edit " .. vim.fn.fnameescape(path))
                    end
                    -- Refresh the tree
                    if picker and picker.finder then
                      pcall(function() picker:find() end)
                    end
                  end,
                },
              },
            },
          },
        },
      })
    end,
  },
}
