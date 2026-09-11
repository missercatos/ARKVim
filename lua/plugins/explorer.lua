-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete is available as <space>fd (File → Delete) only.
-- The bare `d` default is removed so it cannot be triggered by accident
-- while the global <space>d (debug/DAP) prefix is also active.
-- `a` is overridden: auto-detect target dir from cursor position + project language extension.
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
                    local lang = vim.g.arkvim_project_lang
                    local lang_ext = {
                      java = "java", python = "py", rust = "rs", go = "go",
                      c = "c", cpp = "cpp", devops = "yml",
                    }

                    -- Determine target directory from cursor position
                    local base = picker:cwd()
                    local item = picker.list and picker.list:current()
                    if item then
                      if item.dir then
                        -- Cursor on a folder → create inside it
                        base = item.file
                      else
                        -- Cursor on a file → create in same directory
                        base = vim.fn.fnamemodify(item.file, ":h")
                      end
                    end

                    local name = vim.fn.input("新建文件名 (" .. base .. "): ")
                    if name == "" then
                      return
                    end

                    -- If name contains "/", treat as relative path from cwd
                    local path
                    if name:find("/") then
                      path = picker:cwd() .. "/" .. name
                    else
                      path = base .. "/" .. name
                    end

                    -- Auto-append extension if no extension given
                    if lang and vim.fn.fnamemodify(path, ":e") == "" then
                      local ext = lang_ext[lang]
                      if ext then
                        path = path .. "." .. ext
                      end
                    end

                    -- Create file and open it
                    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                    vim.cmd("edit " .. vim.fn.fnameescape(path))

                    -- Refresh the tree
                    pcall(function() picker:find() end)
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
