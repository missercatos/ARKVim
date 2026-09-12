local M = {}

local map = vim.keymap.set

local function run(cmd, cwd)
  local target = cwd
  if not target then
    local ok, out = pcall(vim.fn.systemlist, { "git", "rev-parse", "--show-toplevel" })
    if ok and #out > 0 and vim.v.shell_error == 0 then
      target = out[1]
    else
      target = vim.fn.getcwd()
    end
  end
  local output = vim.fn.systemlist(cmd, target)
  local ok = vim.v.shell_error == 0
  return ok, output
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function in_tmux_or_float(cmd, title)
  local ok, out = pcall(vim.fn.systemlist, { "git", "rev-parse", "--show-toplevel" })
  local cwd = (ok and #out > 0 and vim.v.shell_error == 0) and out[1] or vim.fn.getcwd()
  if vim.fn.executable("tmux") == 1 and os.getenv("TMUX") then
    vim.fn.jobstart({ "tmux", "split-window", "-l", "30%", "-c", cwd,
      "bash", "-c", cmd .. "; echo '按 Enter 退出'; read" }, { detach = true })
  else
    Snacks.terminal({ "bash", "-c", cmd .. "; echo; echo '按 Enter 退出'; read" }, {
      cwd = cwd,
      win = { title = title or "Git", position = "float" },
    })
  end
end

function M.setup()
  local function is_git_repo()
    local ok, out = pcall(vim.fn.systemlist, { "git", "rev-parse", "--show-toplevel" })
    return ok and #out > 0 and vim.v.shell_error == 0
  end

  -- 说明：which-key 分组在 config/keymaps.lua 里注册。
  -- 这里不能注册：本模块在 lazy.setup() 之前执行，which-key 还没在 rtp 上，
  -- pcall(require, "which-key") 必然失败（原代码是死代码）。

  -- <leader>Gb — 交互式切换分支 (Snacks picker)
  map("n", "<leader>Gb", function()
    if not is_git_repo() then
      notify("不在 Git 仓库中", vim.log.levels.WARN)
      return
    end
    local ok, branches = run({ "git", "branch", "--sort=-committerdate", "--format=%(refname:short)" })
    if not ok or #branches == 0 then
      notify("没有找到分支", vim.log.levels.WARN)
      return
    end
    Snacks.picker({
      source = {
        items = branches,
        name = "Git Branches",
        format = function(item) return item end,
        confirm = function(picker, item)
          if item then
            picker:close()
            local _, out = run({ "git", "checkout", item })
            if vim.v.shell_error == 0 then
              notify("切换到分支: " .. item)
            else
              notify("切换失败: " .. table.concat(out, "\n"), vim.log.levels.ERROR)
            end
          end
        end,
      },
    })
  end, { desc = "Switch branch" })

  -- <leader>Gb — 按 backspace 切换到 remote tracking 分支
  -- (Snacks picker 支持输入过滤，输入分支名即可搜索)

  -- <leader>Gs — fetch --all --prune
  map("n", "<leader>Gs", function()
    in_tmux_or_float("git fetch --all --prune && echo 'Fetch 完成'", "Git Fetch")
  end, { desc = "Fetch all + prune" })

  -- <leader>Gl — pull
  map("n", "<leader>Gl", function()
    in_tmux_or_float("git pull --rebase && echo 'Pull 完成'", "Git Pull")
  end, { desc = "Pull (rebase)" })

  -- <leader>Gu — push (set upstream if needed)
  map("n", "<leader>Gu", function()
    in_tmux_or_float("git push -u origin HEAD && echo 'Push 完成'", "Git Push")
  end, { desc = "Push to origin (set upstream)" })

  -- <leader>Gc — 一键提交 (stage all + prompt message)
  map("n", "<leader>Gc", function()
    if not is_git_repo() then
      notify("不在 Git 仓库中", vim.log.levels.WARN)
      return
    end
    local ok, status = run({ "git", "status", "--porcelain" })
    if not ok then
      notify("git status 失败", vim.log.levels.ERROR)
      return
    end
    if #status == 0 then
      notify("没有改动需要提交", vim.log.levels.INFO)
      return
    end
    vim.ui.input({ prompt = "提交信息: ", default = "" }, function(msg)
      if not msg or msg == "" then
        notify("取消提交", vim.log.levels.INFO)
        return
      end
      run({ "git", "add", "-A" })
      local _, out = run({ "git", "commit", "-m", msg })
      if vim.v.shell_error == 0 then
        notify("提交成功: " .. msg)
      else
        notify("提交失败: " .. table.concat(out, "\n"), vim.log.levels.ERROR)
      end
    end)
  end, { desc = "Commit all" })

  -- <leader>Gp — 创建 PR
  map("n", "<leader>Gp", function()
    if vim.fn.executable("gh") ~= 1 then
      notify("gh CLI 未安装", vim.log.levels.ERROR)
      return
    end
    local ok, output = run({ "git", "branch", "--show-current" })
    if not ok or #output == 0 then
      notify("获取当前分支失败", vim.log.levels.WARN)
      return
    end
    local branch = output[1]:gsub("%s+$", "")
    if branch == "main" or branch == "master" then
      notify("当前分支是 " .. branch .. "，请切换到功能分支", vim.log.levels.WARN)
      return
    end
    vim.ui.input({ prompt = "PR 标题: ", default = "" }, function(title)
      if not title or title == "" then
        notify("取消创建 PR", vim.log.levels.INFO)
        return
      end
      vim.ui.input({ prompt = "PR 描述 (可选): ", default = "" }, function(body)
        body = body or ""
        in_tmux_or_float(
          string.format('gh pr create --title "%s" --body "%s" --fill', title, body),
          "Create PR"
        )
      end)
    end)
  end, { desc = "Create PR" })

  -- <leader>Go — 检出 PR (列出所有 open PR → 选择 → gh pr checkout)
  map("n", "<leader>Go", function()
    if vim.fn.executable("gh") ~= 1 then
      notify("gh CLI 未安装", vim.log.levels.ERROR)
      return
    end
    local ok, output = run({ "gh", "pr", "list", "--state", "open", "--limit", "50" })
    if not ok or #output == 0 then
      notify("没有找到 open PR", vim.log.levels.INFO)
      return
    end
    local items = {}
    for _, line in ipairs(output) do
      local num, title, branch, author = line:match("^(%d+)%s+(.-)%s+(%S+)%s+by%s+(.+)$")
      if num then
        table.insert(items, string.format("#%s %s (%s by %s)", num, title, branch, author))
      else
        table.insert(items, line)
      end
    end
    if #items == 0 then
      notify("没有找到 open PR", vim.log.levels.INFO)
      return
    end
    Snacks.picker({
      source = {
        items = items,
        name = "GitHub PRs",
        format = function(item) return item end,
        confirm = function(picker, item)
          if item then
            picker:close()
            local num = item:match("^#(%d+)")
            if num then
              in_tmux_or_float("gh pr checkout " .. num, "Checkout PR #" .. num)
            end
          end
        end,
      },
    })
  end, { desc = "Checkout PR" })

  -- <leader>Gv — 浏览器打开 PR
  map("n", "<leader>Gv", function()
    if vim.fn.executable("gh") ~= 1 then
      notify("gh CLI 未安装", vim.log.levels.ERROR)
      return
    end
    in_tmux_or_float("gh pr view --web", "View PR")
  end, { desc = "Open PR in browser" })

  -- <leader>Gf — fork 仓库
  map("n", "<leader>Gf", function()
    if vim.fn.executable("gh") ~= 1 then
      notify("gh CLI 未安装", vim.log.levels.ERROR)
      return
    end
    in_tmux_or_float("gh repo fork --clone && echo 'Fork 完成'", "Fork Repo")
  end, { desc = "Fork repo" })

  -- <leader>Gi — 列出 issue
  map("n", "<leader>Gi", function()
    if vim.fn.executable("gh") ~= 1 then
      notify("gh CLI 未安装", vim.log.levels.ERROR)
      return
    end
    local ok, output = run({ "gh", "issue", "list", "--state", "open", "--limit", "50" })
    if not ok or #output == 0 then
      notify("没有找到 open issue", vim.log.levels.INFO)
      return
    end
    local items = {}
    for _, line in ipairs(output) do
      local num, title = line:match("^(%d+)%s+(.+)$")
      if num then
        table.insert(items, string.format("#%s %s", num, title))
      else
        table.insert(items, line)
      end
    end
    Snacks.picker({
      source = {
        items = items,
        name = "GitHub Issues",
        format = function(item) return item end,
        confirm = function(picker, item)
          if item then
            picker:close()
            local num = item:match("^#(%d+)")
            if num then
              in_tmux_or_float("gh issue view " .. num .. " --web", "View Issue #" .. num)
            end
          end
        end,
      },
    })
  end, { desc = "List issues" })
end

return M
