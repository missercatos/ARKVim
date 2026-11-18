-- arkvim/notebook.lua — Jupyter/molten + sniprun 的按需初始化
-- rplugin 的 manifest（~/.local/share/nvim/rplugin.vim）不在启动时加载，
-- 改成首次使用时按需注册。

local M = {}

local MOLTEN_PLUGIN = "benlubas/molten-nvim"

--- 确保 molten 的 rplugin 已注册；返回 true 表示 :MoltenInit 可用
function M.molten_ensure()
  if vim.fn.exists(":MoltenInit") == 2 then
    return true
  end
  local manifest = vim.fn.stdpath("data") .. "/rplugin.vim"
  local molten_dir = vim.fn.stdpath("data") .. "/lazy/molten-nvim"

  local ok = pcall(function()
    require("lazy").load({ plugins = { MOLTEN_PLUGIN } })
    -- lazy.load 可能是异步的；必须确保 molten 已经在 runtimepath 上，
    -- 否则 :UpdateRemotePlugins 扫不到它的 rplugin/ 目录（会生成空 manifest）。
    if not vim.o.rtp:find(molten_dir, 1, true) then
      vim.opt.rtp:append(molten_dir)
    end
    vim.cmd("UpdateRemotePlugins")
    if vim.fn.filereadable(manifest) == 1 then
      vim.cmd("source " .. vim.fn.fnameescape(manifest))
    end
  end)
  if not ok or vim.fn.exists(":MoltenInit") ~= 2 then
    vim.notify(
      "molten 初始化失败。请确认 python3 与 pynvim：\npip install --user pynvim",
      vim.log.levels.ERROR,
      { title = "ARKVIM" }
    )
    return false
  end
  return true
end

--- Molten: initialize
function M.molten_init()
  if not M.molten_ensure() then
    return
  end
  vim.cmd("MoltenInit")
  vim.notify("molten 已初始化 — 打开 .ipynb 即可运行", vim.log.levels.INFO)
end

--- 执行一条 molten 命令（先确保 rplugin 注册）
function M.molten_cmd(cmd)
  if not M.molten_ensure() then
    return
  end
  vim.cmd(cmd)
end

--- Sniprun: 执行当前 snippet
function M.sniprun_run()
  vim.cmd("SnipRun")
end

return M
