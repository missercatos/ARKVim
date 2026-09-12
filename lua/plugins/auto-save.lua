return {
  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      enabled = true,
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost" },
        defer_save = { "InsertLeave", "TextChanged" },
        cancel_deferred_save = { "InsertEnter" },
      },
      condition = function(buf)
        local ft = vim.bo[buf].filetype
        -- 跳过特殊 buffer
        if ft == "" or ft == "NvimTree" or ft == "neo-tree" or ft == "SnacksDashboard" then
          return false
        end
        if vim.bo[buf].buftype ~= "" then
          return false
        end
        return true
      end,
      write_all_buffers = false,
      -- 关键：自动保存不触发 autocmd（不跑 conform 的 format_on_save），
      -- 这样写代码时不会被实时格式化/对齐，也不会把展开的 {} 折叠回去。
      -- 格式化只在手动 :w 时发生。
      noautocmd = true,
      lockmarks = false,
      debounce_delay = 1000,
      minimization_detection = function()
        if vim.fn.line("$") > 10000 then
          return false
        end
        return true
      end,
    },
  },
}
