-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete is available as <space>fd (File → Delete) only.
-- The bare `d` default is removed so it cannot be triggered by accident
-- while the global <space>d (debug/DAP) prefix is also active.
-- `a` is overridden: cursor-aware + project language extension.
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
                  ["a"] = function(picker)
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")

                    -- Use picker:dir() to get current directory (folder cursor or file's parent)
                    local base = picker:dir()

                    local lang = vim.g.arkvim_project_lang
                    local lang_ext = {
                      java = "java", python = "py", rust = "rs", go = "go",
                      c = "c", cpp = "cpp", devops = "yml",
                    }

                    local name = vim.fn.input("新建文件 (" .. vim.fn.fnamemodify(base, ":t") .. "/): ")
                    if not name or name == "" then
                      return
                    end

                    -- Resolve path: "/" prefix = relative to cwd, otherwise relative to base
                    local path
                    if name:sub(1, 1) == "/" then
                      path = vim.fn.fnamemodify(picker:cwd() .. name, ":p")
                    else
                      path = base .. "/" .. name
                    end

                    -- Auto-append extension only in scaffold projects
                    if lang and vim.fn.fnamemodify(path, ":e") == "" then
                      local ext = lang_ext[lang]
                      if ext then
                        path = path .. "." .. ext
                      end
                    end

                    -- Create the file
                    local dir = vim.fn.fnamemodify(path, ":h")
                    vim.fn.mkdir(dir, "p")
                    if vim.fn.filereadable(path) == 0 then
                      io.open(path, "w"):close()
                    end

                    -- Open parent dir in tree, refresh, and center on new file
                    Tree:open(dir)
                    Tree:refresh(dir)
                    Actions.update(picker, { target = path })

                    -- Open the file in editor
                    vim.cmd("edit " .. vim.fn.fnameescape(path))
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
