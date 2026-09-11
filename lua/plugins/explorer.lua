-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete: <space>fd | `d` removed to avoid conflict with <space>d (DAP).
-- `a`: single file/dir (relative to cursor)
-- `A`: multi-file batch create (one path per line, relative to cwd)
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

                  -- `a` — single create relative to cursor
                  ["a"] = function(_win)
                    local pickers = Snacks.picker.get({ source = "explorer" })
                    local picker = pickers and pickers[1]
                    if not picker then return end
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")
                    local base = picker:dir()

                    local name = vim.fn.input("新建 (" .. vim.fn.fnamemodify(base, ":t") .. "/): ")
                    if not name or name == "" then return end

                    local path
                    if name:sub(1, 1) == "/" then
                      path = vim.fn.fnamemodify(picker:cwd() .. name, ":p")
                    else
                      path = base .. "/" .. name
                    end

                    if name:sub(-1) == "/" then
                      vim.fn.mkdir(path, "p")
                    else
                      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                      if vim.fn.filereadable(path) == 0 then
                        io.open(path, "w"):close()
                      end
                    end

                    Tree:open(vim.fn.fnamemodify(path, ":h"))
                    Tree:refresh(vim.fn.fnamemodify(path, ":h"))
                    Actions.update(picker, { target = path })
                  end,

                  -- `A` — multi-file batch create (floating input)
                  ["A"] = function(_win)
                    local pickers = Snacks.picker.get({ source = "explorer" })
                    local picker = pickers and pickers[1]
                    if not picker then return end
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")
                    local cwd = picker:cwd()

                    -- Open floating window with scratch buffer
                    local buf = vim.api.nvim_create_buf(false, true)
                    vim.bo[buf].buftype = "nofile"
                    vim.bo[buf].bufhidden = "wipe"
                    vim.bo[buf].filetype = "arkvim-batch-create"

                    local width = math.min(60, vim.o.columns - 4)
                    local height = 12
                    local win = vim.api.nvim_open_win(buf, true, {
                      relative = "editor",
                      width = width,
                      height = height,
                      row = math.floor((vim.o.lines - height) / 2),
                      col = math.floor((vim.o.columns - width) / 2),
                      style = "minimal",
                      border = "rounded",
                    })

                    -- Set buffer lines
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
                      "# 输入文件/目录路径，每行一个",
                      "# 结尾带 / 创建目录，否则创建文件",
                      "# 相对于: " .. cwd,
                      "#",
                    })
                    vim.api.nvim_win_set_cursor(win, { 5, 0 })

                    -- Keymaps
                    local function confirm()
                      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                      local created = 0
                      local last_path = nil
                      for _, line in ipairs(lines) do
                        line = line:match("^%s*(.-)%s*$") -- trim
                        if line ~= "" and line:sub(1, 1) ~= "#" then
                          local path = cwd .. "/" .. line
                          if line:sub(-1) == "/" then
                            vim.fn.mkdir(path, "p")
                          else
                            vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                            if vim.fn.filereadable(path) == 0 then
                              io.open(path, "w"):close()
                            end
                          end
                          last_path = path
                          created = created + 1
                        end
                      end
                      vim.api.nvim_win_close(win, true)
                      if created > 0 then
                        -- Refresh tree, center on last created item
                        pcall(function()
                          Tree:open(vim.fn.fnamemodify(last_path, ":h"))
                          Tree:refresh(vim.fn.fnamemodify(last_path, ":h"))
                          Actions.update(picker, { target = last_path })
                        end)
                        vim.notify("已创建 " .. created .. " 个项目")
                      end
                    end

                    local function cancel()
                      vim.api.nvim_win_close(win, true)
                    end

                    vim.keymap.set("n", "<C-s>", confirm, { buffer = buf, silent = true })
                    vim.keymap.set("i", "<C-s>", function()
                      vim.cmd("stopinsert")
                      confirm()
                    end, { buffer = buf, silent = true })
                    vim.keymap.set("n", "q", cancel, { buffer = buf, silent = true })
                    vim.keymap.set("i", "<C-q>", function()
                      vim.cmd("stopinsert")
                      cancel()
                    end, { buffer = buf, silent = true })
                    vim.keymap.set("n", "<Esc>", cancel, { buffer = buf, silent = true })
                    vim.keymap.set("i", "<Esc>", function()
                      vim.cmd("stopinsert")
                      cancel()
                    end, { buffer = buf, silent = true })

                    -- Enter in normal mode adds new line
                    vim.keymap.set("n", "<CR>", function()
                      local pos = vim.api.nvim_win_get_cursor(win)
                      vim.api.nvim_buf_set_lines(buf, pos[1], pos[1], false, { "" })
                      vim.api.nvim_win_set_cursor(win, { pos[1] + 1, 0 })
                      vim.cmd("startinsert")
                    end, { buffer = buf, silent = true })

                    -- Start in insert mode
                    vim.cmd("startinsert")
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
