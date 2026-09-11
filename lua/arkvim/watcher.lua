local M = {}

local watchers = {} -- bufnr -> { file_watcher, dir_watcher }
local debounce = {} -- bufnr -> uv_timer

local function buf_name(buf)
  return vim.api.nvim_buf_get_name(buf)
end

local function buf_valid_name(buf)
  local name = buf_name(buf)
  return name ~= "" and vim.fn.filereadable(name) == 1
end

local function do_checktime(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local name = buf_name(buf)
  if name == "" then
    return
  end
  local ok, _ = pcall(vim.cmd, "checktime " .. vim.fn.bufnr(name))
  if ok then
    -- 这里不做额外通知，checktime 自己会处理
  end
end

local function debounced_checktime(buf)
  if debounce[buf] then
    debounce[buf]:stop()
    debounce[buf]:close()
  end
  local timer = vim.uv.new_timer()
  debounce[buf] = timer
  timer:start(200, 0, vim.schedule_wrap(function()
    do_checktime(buf)
    if timer then
      timer:stop()
      timer:close()
    end
    debounce[buf] = nil
  end))
end

local function watch_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) or buf_valid_name(buf) == false then
    return
  end

  local file = buf_name(buf)
  local dir = vim.fn.fnamemodify(file, ":h")
  local base = vim.fn.fnamemodify(file, ":t")

  local file_watcher = vim.uv.new_fs_event()
  local dir_watcher = vim.uv.new_fs_event()

  if not file_watcher or not dir_watcher then
    return
  end

  -- 监听文件本身：内容变更 (uv_fs_event:start 的第二个参数是 flags 表)
  file_watcher:start(file, {}, function(err, _, events)
    if err or not events then
      return
    end
    if events.change or events.rename then
      debounced_checktime(buf)
    end
  end)

  -- 监听所在目录：编辑器原子写(临时文件 + rename)会替换原文件
  dir_watcher:start(dir, {}, function(err, fname, events)
    if err or not events or fname ~= base then
      return
    end
    if events.change or events.rename then
      debounced_checktime(buf)
    end
  end)

  watchers[buf] = {
    file = file_watcher,
    dir = dir_watcher,
  }
end

local function unwatch_buf(buf)
  if watchers[buf] then
    if watchers[buf].file then
      watchers[buf].file:stop()
      watchers[buf].file:close()
    end
    if watchers[buf].dir then
      watchers[buf].dir:stop()
      watchers[buf].dir:close()
    end
    watchers[buf] = nil
  end
  if debounce[buf] then
    debounce[buf]:stop()
    debounce[buf]:close()
    debounce[buf] = nil
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("arkvim_file_watcher", { clear = true })

  -- BufEnter: 为当前 buffer 启动监听
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "*",
    callback = function(args)
      local buf = args.buf
      if buf_valid_name(buf) and not watchers[buf] then
        watch_buf(buf)
      end
    end,
  })

  -- BufDelete/BufWipeout: 清理监听
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    pattern = "*",
    callback = function(args)
      unwatch_buf(args.buf)
    end,
  })

  -- FocusGained / CursorHold / InsertLeave: 兜底检查
  vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold", "InsertLeave", "TermLeave" }, {
    group = group,
    pattern = "*",
    callback = function()
      vim.cmd("silent! checktime")
    end,
  })

  -- 手动重载当前文件
  vim.keymap.set("n", "<leader>uR", function()
    vim.cmd("edit!")
    vim.notify("从磁盘重载: " .. vim.fn.expand("%:t"))
  end, { desc = "Reload from disk", silent = true })

  -- :ReloadAllChanged — 重载所有已改变的文件
  vim.api.nvim_create_user_command("ReloadAllChanged", function()
    local bufs = vim.api.nvim_list_bufs()
    local count = 0
    for _, buf in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" and vim.fn.filereadable(name) == 1 then
          local ok = pcall(vim.cmd, "checktime " .. buf)
          if ok then
            count = count + 1
          end
        end
      end
    end
    vim.notify("检查了所有 buffer，重载了 " .. count .. " 个")
  end, { desc = "Reload all changed buffers" })

  -- FileChangedShell: 当外部修改被检测到时
  -- 未修改的 buffer 会静默重载（autoread=true + checktime）
  -- 已修改的 buffer 不会自动重载（防止丢失改动），仅通知
  vim.api.nvim_create_autocmd("FileChangedShell", {
    group = group,
    callback = function(args)
      local buf = args.buf
      if vim.bo[buf].modified then
        local name = vim.api.nvim_buf_get_name(buf)
        vim.notify(
          string.format("%s 已被外部修改（缓冲区有未保存改动）\n按 <leader>uR 重载或保存后重试", vim.fn.fnamemodify(name, ":t")),
          vim.log.levels.WARN
        )
      end
    end,
  })
end

return M
