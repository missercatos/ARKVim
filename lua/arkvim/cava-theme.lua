local M = {}

local function resolve_source()
  local config = vim.fn.expand("~/.config/cava/config")
  if vim.fn.filereadable(config) == 0 then
    return nil
  end
  local lines = vim.fn.readfile(config)
  for _, line in ipairs(lines) do
    local theme = line:match("theme%s*=%s*'([^']+)'")
    if theme then
      local tpath = vim.fn.expand("~/.config/cava/themes/" .. theme)
      if vim.fn.filereadable(tpath) == 1 then
        return tpath
      end
    end
  end
  return config
end

local function parse_gradient_colors(source)
  local lines = vim.fn.readfile(source)
  local colors = {}
  for _, line in ipairs(lines) do
    -- strip leading comment markers (; or #)
    local cleaned = line:gsub("^%s*[;#]%s*", "")
    local idx, hex = cleaned:match("gradient_color_(%d)%s*=%s*'?#([0-9a-fA-F]+)'?")
    if idx then
      colors[tonumber(idx)] = "#" .. hex
    end
  end
  return #colors > 0 and colors or nil
end

function M.read_cava_colors()
  local source = resolve_source()
  if not source then
    return nil
  end
  return parse_gradient_colors(source)
end

return M
