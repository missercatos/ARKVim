-- arkvim/hints.lua — capability hub + per-project capability auto-load

local M = {}

--- Capability hub picker
function M.open()
  local project = require("arkvim.project")
  local caps = require("arkvim.capabilities")
  local proj = project.current()

  local items = {}

  if proj then
    table.insert(items, {
      text = string.format("%s  %s @ %s", "📁", proj.label or proj.kind or "?", proj.root),
      kind = "header",
    })

    local proj_caps = caps.for_kind(proj.kind or "")
    local loaded, on_demand = {}, {}
    for _, cap in ipairs(proj_caps) do
      if cap.auto then
        table.insert(loaded, cap)
      else
        table.insert(on_demand, cap)
      end
    end

    for _, cap in ipairs(loaded) do
      table.insert(items, {
        text = string.format("  [已加载] %s", cap.label),
        kind = "loaded",
        cap_id = cap.id,
      })
    end

    for _, cap in ipairs(on_demand) do
      local hint = cap.hint and (" · " .. cap.hint) or ""
      table.insert(items, {
        text = string.format("  [可加载] %s%s", cap.label, hint),
        kind = "available",
        cap_id = cap.id,
      })
    end
  else
    table.insert(items, {
      text = "未检测到项目",
      kind = "header",
    })
  end

  if #items == 0 then
    vim.notify("没有可用的能力", vim.log.levels.INFO)
    return
  end

  Snacks.picker({
    source = {
      items = items,
      name = "能力面板",
      format = function(item) return item.text end,
      confirm = function(picker, item)
        if item and item.cap_id then
          picker:close()
          local ok = caps.load(item.cap_id)
          if ok then
            vim.notify("已加载: " .. item.text:match("%] (.+)") or item.cap_id, vim.log.levels.INFO)
          else
            vim.notify("加载失败: " .. (item.cap_id or ""), vim.log.levels.ERROR)
          end
        end
      end,
    },
  })
end

--- Setup: per-project capability auto-load (no popup)
function M.setup()
  local grp = vim.api.nvim_create_augroup("arkvim_hints", { clear = true })
  local project = require("arkvim.project")
  local caps = require("arkvim.capabilities")

  local last_root = nil

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = grp,
    callback = function()
      vim.schedule(function()
        local proj = project.current()
        if not proj or proj.root == last_root then return end
        last_root = proj.root

        -- Auto-load capabilities（按项目类型加载对应模块）
        caps.auto_load(proj.kind or "")

        -- 注意：不再自动 popup「可用能力」提示，避免进入项目时弹窗。
        -- 需要时用 <leader>Xh 打开 Capability Hub。
      end)
    end,
  })
end

return M
