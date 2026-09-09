-- ARKVIM dependencies guard (runs on VeryLazy, no startup cost)
-- The Snacks file explorer (<space>e) search relies on the `fd` binary.
-- When it is missing we auto-install a static build into ~/.local/bin
-- (Linux x86_64 only; elsewhere we print the install hint instead).

local M = {}

local function notify(msg, level)
  vim.notify("[arkvim] " .. msg, level or vim.log.levels.WARN)
end

local function fd_installed()
  return vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1
end

---@return string? url
local function release_url()
  local sysname = vim.loop.os_uname().sysname
  local machine = vim.loop.os_uname().machine
  if sysname ~= "Linux" then
    return nil
  end
  local target
  if machine == "x86_64" then
    target = "x86_64-unknown-linux-gnu"
  elseif machine == "aarch64" then
    target = "aarch64-unknown-linux-gnu"
  else
    return nil
  end
  return "https://github.com/sharkdp/fd/releases/latest/download/fd-*_" .. target .. ".tar.gz"
end

function M.check_fd()
  if fd_installed() then
    return
  end
  local bin = vim.fn.stdpath("data") .. "/arkvim/bin"
  vim.fn.mkdir(bin, "p")

  local url = release_url()
  if not url then
    notify("未找到 fd。Snacks 文件树搜索需要它。请安装 fd（如: sudo pacman -S fd / apt install fd-find）")
    return
  end

  notify("未找到 fd，正在自动安装到 ~/.local/share/nvim/arkvim/bin …", vim.log.levels.INFO)
  local sh = vim.fn.tempname() .. ".sh"
  local script = string.format([[
set -e
url=%s
asset=$(curl -fsSL --max-time 20 -o /dev/null -w '%%{url_effective}' "$url" | sed 's|.*/||')
base=$(printf '%%s' "$asset" | sed 's/\.tar\.gz$//')
tag=$(printf '%%s' "${base#fd-}" | sed 's/-.*//')
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --max-time 90 -o "$tmp/archive.tar.gz" "https://github.com/sharkdp/fd/releases/download/$tag/$asset"
tar xzf "$tmp/archive.tar.gz" -C "$tmp"
install -m755 "$tmp/$base/fd" "%s/fd"
]], vim.fn.shellescape(url), vim.fn.shellescape(bin))

  vim.fn.writefile(vim.split(script, "\n", { plain = true }), sh)
  vim.fn.setfperm(sh, "755")
  local env = vim.fn.environ()
  vim.fn.jobstart({ sh }, {
    env = env,
    on_exit = function(_, code)
      vim.fn.delete(sh)
      if code == 0 then
        vim.env.PATH = bin .. ":" .. vim.env.PATH
        notify("fd 安装成功: " .. bin .. "/fd", vim.log.levels.INFO)
      else
        notify("fd 自动安装失败，请手动安装后重试。explorer 搜索将不可用。", vim.log.levels.ERROR)
      end
    end,
  })
end

function M.check_all()
  if not vim.g.tactical then
    M.check_fd()
  end
end

return M
