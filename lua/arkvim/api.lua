-- arkvim/api.lua — API browser + semi-automatic notes
-- Aggregates: LSP symbols (project + third-party), treesitter signatures,
-- and manual notes. Opens in a Snacks picker with preview.

local M = {}

local STATE_DIR = vim.fn.stdpath("state") .. "/arkvim"
local NOTES_FILE = STATE_DIR .. "/api_notes.json"

-- ---------------------------------------------------------------------------
-- notes store
-- ---------------------------------------------------------------------------

local function notes_load()
  vim.fn.mkdir(STATE_DIR, "p")
  if vim.fn.filereadable(NOTES_FILE) == 0 then return {} end
  local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(NOTES_FILE))
  return (ok and type(data) == "table") and data or {}
end

local function notes_save(notes)
  vim.fn.mkdir(STATE_DIR, "p")
  vim.fn.writefile({ vim.fn.json_encode(notes) }, NOTES_FILE)
end

local function project_key()
  return vim.fn.getcwd()
end

--- Add or update a note for a symbol
--- @param name string symbol name
--- @param note string the note/comment
--- @param file string|nil source file
function M.annotate(name, note, file)
  local notes = notes_load()
  local key = project_key()
  notes[key] = notes[key] or {}
  notes[key][name] = {
    note = note,
    file = file or vim.fn.expand("%:p"),
    line = vim.fn.line("."),
    updated = os.time(),
  }
  notes_save(notes)
  vim.notify("已保存注释: " .. name)
end

--- Get note for a symbol
function M.get_note(name)
  local notes = notes_load()
  local key = project_key()
  return notes[key] and notes[key][name] or nil
end

--- Delete a note
function M.delete_note(name)
  local notes = notes_load()
  local key = project_key()
  if notes[key] and notes[key][name] then
    notes[key][name] = nil
    notes_save(notes)
    vim.notify("已删除注释: " .. name)
  end
end

-- ---------------------------------------------------------------------------
-- symbol collection
-- ---------------------------------------------------------------------------

--- Collect treesitter symbols from current buffer
local function ts_symbols()
  local ok, parsers = pcall(require, "nvim-treesitter")
  if not ok then return {} end

  local lang = vim.bo.filetype
  local ok2, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok2 then return {} end

  local root = ts_utils.get_node()
  if not root then return {} end

  local symbols = {}
  local seen = {}

  -- iterate top-level nodes
  local function walk(node, depth)
    if depth > 3 then return end
    for child in node:iter_children() do
      local type = child:type()
      local name_node = nil
      -- function/method/class definitions
      if type:find("function_definition") or type:find("method_definition") or type:find("class_definition") or type:find("interface_definition") or type:find("struct_item") or type:find("function_item") or type:find("impl_item") or type:find("trait_item") or type:find("enum_item") or type:find("type_item") or type:find("mod_item") then
        -- extract name
        for c in child:iter_children() do
          local ct = c:type()
          if ct == "name" or ct == "identifier" or ct == "field_identifier" or ct == "type_identifier" or ct == "shorthand_field_identifier" then
            name_node = c
            break
          end
        end
        if name_node then
          local name = vim.treesitter.get_node_text(name_node, 0)
          if name and not seen[name] then
            seen[name] = true
            -- get line for context
            local row = child:start()
            local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
            -- extract doc comment (look up to 3 lines above)
            local doc = ""
            for i = 1, 3 do
              local prev = vim.api.nvim_buf_get_lines(0, math.max(0, row - i), row - i + 1, false)[1] or ""
              if prev:match("^%s*(%-%-?%s*.+)") then
                doc = (doc ~= "" and doc .. " " or "") .. prev:match("^%s*%-%-?%s*(.+)")
              elseif prev:match("^%s*(///.+)") then
                doc = (doc ~= "" and doc .. " " or "") .. prev:match("^%s*///%s*(.+)")
              elseif prev:match("^%s*(#.*)") then
                -- lua doc comment
                local d = prev:match("^%s*#%s*(.+)")
                if d then doc = (doc ~= "" and doc .. " " or "") .. d end
              else
                break
              end
            end
            symbols[#symbols + 1] = {
              name = name,
              kind = type,
              line = row + 1,
              file = vim.fn.expand("%:p"),
              signature = line_text:match("^%s*(.-)%s*$"),
              doc = doc,
            }
          end
        end
      end
      walk(child, depth + 1)
    end
  end

  walk(root, 0)
  return symbols
end

--- Collect LSP symbols (workspace-wide, includes third-party)
local function lsp_symbols(query, callback)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    -- try getting any client
    clients = vim.lsp.get_clients()
  end
  if #clients == 0 then return {} end

  local results = {}
  local done = 0

  for _, client in ipairs(clients) do
    local params = { query = query or "" }
    local ok, req_id = pcall(client.request, "workspace/symbol", params, function(err, result)
      if err or not result then
        done = done + 1
        return
      end
      for _, sym in ipairs(result) do
        local loc = sym.location
        local range = loc.range or (loc.selectionRange or {})
        local line = (range.start and range.start.line or 0) + 1
        local file = vim.uri_to_fname(loc.uri or "")
        results[#results + 1] = {
          name = sym.name,
          kind = vim.lsp.protocol.SymbolKind[sym.kind] or ("kind_" .. tostring(sym.kind)),
          line = line,
          file = file,
          detail = sym.detail or "",
          doc = "",
        }
      end
      done = done + 1
    end)
    if not ok then done = done + 1 end
  end

  -- wait up to 2 seconds
  local waited = 0
  while done < #clients and waited < 20 do
    vim.wait(100, function() return done >= #clients end, 100)
    waited = waited + 1
  end

  return results
end

--- Merge all sources: LSP + treesitter + notes
local function collect_all()
  local all = {}

  -- LSP symbols
  local lsp = lsp_symbols("")
  for _, s in ipairs(lsp) do
    s.source = "lsp"
    all[#all + 1] = s
  end

  -- treesitter symbols
  local ts = ts_symbols()
  for _, s in ipairs(ts) do
    s.source = "ts"
    all[#all + 1] = s
  end

  -- notes
  local notes = notes_load()
  local key = project_key()
  if notes[key] then
    for name, note in pairs(notes[key]) do
      all[#all + 1] = {
        name = name,
        kind = "note",
        line = note.line or 0,
        file = note.file or "",
        detail = "",
        doc = note.note,
        source = "note",
      }
    end
  end

  return all
end

-- ---------------------------------------------------------------------------
-- picker
-- ---------------------------------------------------------------------------

function M.open()
  local symbols = collect_all()
  if #symbols == 0 then
    vim.notify("未找到任何符号 (LSP 未启动或无 treesitter)", vim.log.levels.WARN)
    return
  end

  -- sort: by kind then name
  table.sort(symbols, function(a, b)
    if a.kind ~= b.kind then return a.kind < b.kind end
    return a.name < b.name
  end)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local list_h = math.min(18, #symbols + 2)
  local win_w = 60
  local total_h = list_h + 2  -- list + preview
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_w,
    height = total_h,
    row = math.floor((vim.o.lines - total_h) / 2),
    col = math.floor((vim.o.columns - win_w) / 2),
    style = "minimal",
    border = "rounded",
  })

  local cursor = 1
  local scroll_offset = 0
  local ns = vim.api.nvim_create_namespace("arkvim_api")
  local preview_h = 5
  local list_area_h = total_h - preview_h - 1  -- separator

  local function render()
    local visible = math.min(list_area_h, #symbols - scroll_offset)
    local lines = {}
    -- list part
    for i = scroll_offset + 1, math.min(scroll_offset + list_area_h, #symbols) do
      local s = symbols[i]
      local mark = i == cursor and "> " or "  "
      local tag = ""
      if s.source == "note" then tag = " [note]"
      elseif s.source == "lsp" then tag = " [lsp]"
      else tag = " [ts]" end
      lines[#lines + 1] = mark .. s.name .. "  (" .. s.kind .. ")" .. tag
    end
    while #lines < list_area_h do lines[#lines + 1] = "" end
    -- separator
    lines[#lines + 1] = string.rep("─", win_w)
    -- preview part
    local sel = symbols[cursor]
    if sel then
      local preview = {}
      preview[#preview + 1] = "名称: " .. sel.name
      preview[#preview + 1] = "类型: " .. sel.kind
      if sel.signature and sel.signature ~= "" then
        preview[#preview + 1] = "签名: " .. sel.signature
      end
      if sel.detail and sel.detail ~= "" then
        preview[#preview + 1] = "详情: " .. sel.detail
      end
      if sel.doc and sel.doc ~= "" then
        preview[#preview + 1] = "说明: " .. sel.doc
      end
      if sel.file and sel.file ~= "" then
        preview[#preview + 1] = "位置: " .. sel.file .. ":" .. sel.line
      end
      for _, l in ipairs(preview) do
        lines[#lines + 1] = l
      end
    end
    while #lines < total_h do lines[#lines + 1] = "" end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- highlight
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local sel_row = cursor - scroll_offset - 1
    if sel_row >= 0 and sel_row < list_area_h then
      vim.api.nvim_buf_add_highlight(buf, ns, "Visual", sel_row, 0, -1)
    end
  end

  local function move(delta)
    cursor = math.max(1, math.min(#symbols, cursor + delta))
    if cursor <= scroll_offset then
      scroll_offset = cursor - 1
    elseif cursor > scroll_offset + list_area_h then
      scroll_offset = cursor - list_area_h
    end
    render()
  end

  local function goto_symbol()
    local sel = symbols[cursor]
    if sel and sel.file and sel.file ~= "" and vim.fn.filereadable(sel.file) == 1 then
      vim.api.nvim_win_close(win, true)
      vim.cmd("edit " .. vim.fn.fnameescape(sel.file))
      pcall(vim.api.nvim_win_set_cursor, 0, { sel.line, 0 })
    end
  end

  local function annotate()
    local sel = symbols[cursor]
    if not sel then return end
    local note = vim.fn.input("注释 " .. sel.name .. ": ")
    if note ~= "" then
      M.annotate(sel.name, note, sel.file)
      -- refresh
      symbols = collect_all()
      table.sort(symbols, function(a, b) return a.kind < b.kind or (a.kind == b.kind and a.name < b.name) end)
      cursor = 1
      scroll_offset = 0
      render()
    end
  end

  local function insert_call()
    local sel = symbols[cursor]
    if not sel then return end
    vim.api.nvim_win_close(win, true)
    -- insert a call template
    local call = sel.name .. "()"
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    local new_line = line:sub(1, col) .. call .. line:sub(col + 1)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
    -- place cursor inside parens
    local pos = col + #sel.name + 1
    pcall(vim.api.nvim_win_set_cursor, 0, { row, pos })
  end

  local km = { buffer = buf, silent = true, nowait = true, noremap = true }
  vim.keymap.set("n", "j", function() move(1) end, km)
  vim.keymap.set("n", "<Down>", function() move(1) end, km)
  vim.keymap.set("n", "k", function() move(-1) end, km)
  vim.keymap.set("n", "<Up>", function() move(-1) end, km)
  vim.keymap.set("n", "<C-d>", function() move(7) end, km)
  vim.keymap.set("n", "<C-u>", function() move(-7) end, km)
  vim.keymap.set("n", "G", function() cursor = #symbols; scroll_offset = math.max(0, #symbols - list_area_h); render() end, km)
  vim.keymap.set("n", "gg", function() cursor = 1; scroll_offset = 0; render() end, km)
  vim.keymap.set("n", "<CR>", goto_symbol, km)
  vim.keymap.set("n", "<Space>", goto_symbol, km)
  vim.keymap.set("n", "a", annotate, km)
  vim.keymap.set("n", "i", insert_call, km)
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, km)
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, km)

  render()
end

function M.setup()
  local map = vim.keymap.set
  map("n", "<leader>ia", function() M.open() end, { desc = "API 浏览器", silent = true })
  map("n", "<leader>in", function()
    local cword = vim.fn.expand("<cword>")
    if cword ~= "" then
      local note = vim.fn.input("注释 " .. cword .. ": ")
      if note ~= "" then
        M.annotate(cword, note)
      end
    end
  end, { desc = "给当前符号加注释", silent = true })
  map("n", "<leader>ii", function()
    local cword = vim.fn.expand("<cword>")
    if cword ~= "" then
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
      local new_line = line:sub(1, col) .. cword .. "()" .. line:sub(col + 1)
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
      pcall(vim.api.nvim_win_set_cursor, 0, { row, col + #cword + 1 })
    end
  end, { desc = "插入调用模板", silent = true })
end

return M
