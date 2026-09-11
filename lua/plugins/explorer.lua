-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete: <space>fd | `d` removed to avoid conflict with <space>d (DAP).
-- `a`: single file/dir (relative to cursor)
-- `A`: multi-file batch create (one path per line, relative to cwd)

local Animate = require("arkvim.animate")

local function get_explorer_picker()
  local pickers = Snacks.picker.get({ source = "explorer" })
  return pickers and pickers[1]
end

local function create_batch_win(cwd)
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

  -- Fade in
  Animate.raw_win(win)

  local header = {
    "# 输入文件/目录路径，每行一个",
    "# 结尾带 / 创建目录，否则创建文件",
    "# 相对于: " .. cwd,
    "#",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
  vim.api.nvim_win_set_cursor(win, { #header + 1, 0 })
  vim.cmd("startinsert")

  return buf, win
end

return {
  -- Snacks explorer keys + animate on open
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- Animate explorer picker on open
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        win = vim.tbl_deep_extend("force", opts.picker and opts.picker.win or {}, {
          list = {
            on_win = function(self)
              Animate.win(self)
            end,
          },
        }),
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["<leader>fd"] = "explorer_del",
                  ["d"] = false,

                  -- `a` — single create relative to cursor
                  ["a"] = function(_win)
                    local picker = get_explorer_picker()
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
                    local picker = get_explorer_picker()
                    if not picker then return end
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")
                    local cwd = picker:cwd()

                    local buf, win = create_batch_win(cwd)

                    local function do_confirm()
                      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                      local created = 0
                      local last_path = nil
                      for _, line in ipairs(lines) do
                        line = line:match("^%s*(.-)%s*$")
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
                      if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                      end
                      if created > 0 then
                        pcall(function()
                          Tree:open(vim.fn.fnamemodify(last_path, ":h"))
                          Tree:refresh(vim.fn.fnamemodify(last_path, ":h"))
                          Actions.update(picker, { target = last_path })
                        end)
                        vim.notify("已创建 " .. created .. " 个项目")
                      end
                    end

                    local function do_cancel()
                      if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                      end
                    end

                    -- Buffer keymaps (work in all modes)
                    local km_opts = { buffer = buf, silent = true, nowait = true }
                    vim.keymap.set("n", "<C-s>", do_confirm, km_opts)
                    vim.keymap.set("i", "<C-s>", function() vim.cmd("stopinsert"); do_confirm() end, km_opts)
                    vim.keymap.set("n", "q", do_cancel, km_opts)
                    vim.keymap.set("i", "<C-q>", function() vim.cmd("stopinsert"); do_cancel() end, km_opts)
                    vim.keymap.set("n", "<Esc>", do_cancel, km_opts)
                    vim.keymap.set("i", "<Esc>", function() vim.cmd("stopinsert"); do_cancel() end, km_opts)

                    -- Enter in normal mode: new line below and enter insert
                    vim.keymap.set("n", "<CR>", function()
                      local pos = vim.api.nvim_win_get_cursor(win)
                      local line_count = vim.api.nvim_buf_line_count(buf)
                      if pos[1] >= line_count then
                        vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
                      else
                        vim.api.nvim_buf_set_lines(buf, pos[1], pos[1], false, { "" })
                      end
                      vim.api.nvim_win_set_cursor(win, { math.min(pos[1] + 1, vim.api.nvim_buf_line_count(buf)), 0 })
                      vim.cmd("startinsert")
                    end, km_opts)

                    -- Tab completion: path suggestion
                    vim.keymap.set("i", "<Tab>", function()
                      local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                      local row = vim.api.nvim_win_get_cursor(win)[1]
                      local text = line[row] or ""
                      if text == "" or text:sub(1, 1) == "#" then
                        return "<Tab>"
                      end
                      -- Try to complete path
                      local base = cwd .. "/" .. text
                      local dir = vim.fn.fnamemodify(base, ":h")
                      local partial = vim.fn.fnamemodify(base, ":t")
                      if vim.fn.isdirectory(dir) == 1 then
                        local entries = vim.fn.readdir(dir)
                        local matches = {}
                        for _, e in ipairs(entries) do
                          if e:find(partial, 1, true) == 1 then
                            table.insert(matches, e)
                          end
                        end
                        if #matches == 1 then
                          local full = dir .. "/" .. matches[1]
                          local is_dir = vim.fn.isdirectory(full) == 1
                          local rel = matches[1] .. (is_dir and "/" or "")
                          line[row] = text .. rel:sub(#partial + 1)
                          vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { line[row] })
                          vim.api.nvim_win_set_cursor(win, { row, #line[row] })
                        elseif #matches > 1 then
                          -- Show candidates
                          vim.notify("候选: " .. table.concat(matches, ", "))
                        end
                      end
                      return ""
                    end, { buffer = buf, silent = true, expr = true })

                    -- Ctrl-n/Ctrl-p for candidate selection
                    vim.keymap.set("i", "<C-n>", "<Tab>", { buffer = buf, silent = true, remap = true })
                    vim.keymap.set("i", "<C-p>", "<S-Tab>", { buffer = buf, silent = true, remap = true })
                  end,
                },
              },
            },
          },
        },
      })
    end,
  },

  -- Animate terminal on open
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        terminal = {
          wo = { winblend = 100 },
          on_win = function(self)
            Animate.win(self)
          end,
        },
      })
    end,
  },
}
