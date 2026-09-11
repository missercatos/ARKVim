-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete: <space>fd | `d` removed to avoid conflict with <space>d (DAP).
-- `a`: create relative to cursor position
-- `A`: create relative to cwd (full path required)
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

                  -- `a` — create relative to cursor (folder → inside it, file → same dir)
                  ["a"] = function(picker)
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")
                    local base = picker:dir()

                    local name = vim.fn.input("新建 (" .. vim.fn.fnamemodify(base, ":t") .. "/): ")
                    if not name or name == "" then
                      return
                    end

                    local path
                    if name:sub(1, 1) == "/" then
                      path = vim.fn.fnamemodify(picker:cwd() .. name, ":p")
                    else
                      path = base .. "/" .. name
                    end

                    local is_dir = name:sub(-1) == "/"
                    if is_dir then
                      vim.fn.mkdir(path, "p")
                    else
                      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                      if vim.fn.filereadable(path) == 0 then
                        io.open(path, "w"):close()
                      end
                    end

                    -- Expand parent dirs, refresh, center on new item
                    Tree:open(vim.fn.fnamemodify(path, ":h"))
                    Tree:refresh(vim.fn.fnamemodify(path, ":h"))
                    Actions.update(picker, { target = path })
                  end,

                  -- `A` — create relative to cwd (full path from root)
                  ["A"] = function(picker)
                    local Actions = require("snacks.explorer.actions")
                    local Tree = require("snacks.explorer.tree")

                    local name = vim.fn.input("新建 (cwd/): ")
                    if not name or name == "" then
                      return
                    end

                    local path = vim.fn.fnamemodify(picker:cwd() .. "/" .. name, ":p")

                    local is_dir = name:sub(-1) == "/"
                    if is_dir then
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
                },
              },
            },
          },
        },
      })
    end,
  },
}
