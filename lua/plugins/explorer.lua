-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete is available as <space>fd (File → Delete) only.
-- The bare `d` default is removed so it cannot be triggered by accident
-- while the global <space>d (debug/DAP) prefix is also active.
-- `a` is overridden: auto-detect target dir from cursor + project language extension.
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
                        base = item.file
                      else
                        base = vim.fn.fnamemodify(item.file, ":h")
                      end
                    end

                    local name = vim.fn.input("新建文件 (" .. vim.fn.fnamemodify(base, ":t") .. "/): ")
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

                    -- Create the file on disk
                    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                    vim.fn.writefile({}, path)

                    -- Find the editor window (not the picker's input/list)
                    local editor_win = nil
                    local picker_wins = {}
                    if picker.layout and picker.layout.wins then
                      for _, w in pairs(picker.layout.wins) do
                        if w.win and vim.api.nvim_win_is_valid(w.win) then
                          picker_wins[w.win] = true
                        end
                      end
                    end
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                      if not picker_wins[win] and vim.api.nvim_win_is_valid(win) then
                        local bt = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
                        if bt == "" or bt == "acwrite" then
                          editor_win = win
                          break
                        end
                      end
                    end

                    -- Open file in the editor window
                    if editor_win then
                      vim.api.nvim_set_current_win(editor_win)
                    end
                    vim.cmd("edit " .. vim.fn.fnameescape(path))

                    -- Refresh the tree and center on the new file
                    pcall(function() picker:find() end)
                    vim.schedule(function()
                      pcall(function()
                        if picker.list then
                          local items = picker.list.items or {}
                          for i, it in ipairs(items) do
                            if it.file == path then
                              picker.list:view(i)
                              break
                            end
                          end
                        end
                      end)
                    end)
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
