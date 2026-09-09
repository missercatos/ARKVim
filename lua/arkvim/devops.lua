-- ARKVIM DevOps (docker / compose) quick actions
-- Runs inside the built-in terminal (Snacks). Triggered by <leader>D*
-- registered in config/keymaps.lua

local M = {}

local function shellescape(s)
  return vim.fn.shellescape(s)
end

-- locate the nearest compose file (from any file inside a compose project)
function M.compose_cwd()
  local cwd = vim.fn.expand("%:p:h")
  local found = vim.fs.find(
    { "compose.yaml", "compose.yml", "docker-compose.yaml", "docker-compose.yml" },
    { upward = true, path = cwd }
  )[1]
  return found and vim.fn.fnamemodify(found, ":h") or cwd
end

local function ensure_snacks()
  if package.loaded["snacks"] then
    return true
  end
  if require("lazy.core.config").plugins["folke/snacks.nvim"] then
    local ok = pcall(require, "lazy").load and pcall(function()
      require("lazy").load({ plugins = { "folke/snacks.nvim" } })
    end)
    if not ok then
      return false
    end
  end
  return package.loaded["snacks"] ~= nil
end

---@param cmd string shell command to run
---@param live boolean? keep the terminal open (logs / exec)
function M.run(cmd, live)
  if vim.fn.executable("docker") ~= 1 then
    vim.notify("未找到 docker", vim.log.levels.WARN)
    return
  end
  if not ensure_snacks() then
    vim.notify("Snacks 尚未就绪，稍后再试", vim.log.levels.WARN)
    return
  end
  local shell = vim.fn.executable("bash") == 1 and "bash" or vim.o.shell
  local full = live and cmd or ("clear && " .. cmd .. "; echo; echo '按 Enter 退出'; read")
  Snacks.terminal({ shell, "-lc", full }, {
    cwd = M.compose_cwd(),
    win = { position = "bottom", height = 0.3 },
  })
end

function M.compose(args, live)
  M.run("docker compose " .. args, live)
end

function M.compose_exec()
  local svc = vim.fn.input("Service: ", "", "file")
  if svc == "" then
    return
  end
  local cmd = vim.fn.input("Command [/bin/sh]: ", "/bin/sh")
  if cmd == "" then
    cmd = "/bin/sh"
  end
  M.compose("exec " .. shellescape(svc) .. " " .. cmd, true)
end

return M
