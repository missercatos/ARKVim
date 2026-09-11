-- File-tree (Snacks explorer, <space>e) key tweaks
-- Delete is available as <space>fd (File → Delete) only.
-- The bare `d` default is removed so it cannot be triggered by accident
-- while the global <space>d (debug/DAP) prefix is also active.
-- `a` is overridden: cursor-aware directory detection.
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

                    -- picker:dir() returns folder path if cursor on dir, or parent if on file
                    local base = picker:dir()

                    local name = vim.fn.input("新建文件 (" .. vim.fn.fnamemodify(base, ":t") .. "/): ")
                    if not name or name == "" then
                      return
                    end

                    -- Resolve: leading "/" = relative to cwd, otherwise relative to cursor dir
                    local path
                    if name:sub(1, 1) == "/" then
                      path = vim.fn.fnamemodify(picker:cwd() .. name, ":p")
                    else
                      path = base .. "/" .. name
                    end

                    -- Create directories + file
                    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
                    if vim.fn.filereadable(path) == 0 then
                      io.open(path, "w"):close()
                    end

                    -- Refresh tree and center on the new file
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
