-- 战术终端 nvim 专用：科学配色 + 准星光标拖影 + 原生极简状态栏
-- 仅在 foot/alacritty（vim.g.tactical）内生效，日用终端不受影响

local M = {}

-- 科学配比原则：色相分语义族，亮度分层级，纯黑底最大对比，每屏至多 6 色
local C = {
  base = "#d4ffd4", -- 基态文本（绿白，最高可读）
  fgbright = "#a8ffa8", -- 函数/调用（亮绿白）
  green = "#33ff33", -- 动作（磷光绿，与战术终端语义一致）
  cyan = "#00e5ff", -- 结构/类型
  amber = "#ffb000", -- 数据/字符串/警告
  gold = "#ffd166", -- 数字/宏
  red = "#ff5555", -- 错误
  darkgreen = "#4a8f4a", -- 注释/提示（层级最低仍清晰）
  dim = "#2f7a2f", -- 行号/装饰
  bgdim = "#0a1f0a", -- 面板底
  cursorbg = "#0f3d0f", -- 准星底（光标拖影）
  selbg = "#2a6a2a", -- 选中/配对
}

local function hl(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

function M.set_highlights()
  -- 语法核心
  hl("Normal", { fg = C.base })
  hl("Comment", { fg = C.darkgreen })
  hl("Constant", { fg = C.amber })
  hl("String", { fg = C.amber })
  hl("Character", { fg = C.amber })
  hl("Number", { fg = C.gold })
  hl("Boolean", { fg = C.gold })
  hl("Float", { fg = C.gold })
  hl("Identifier", { fg = C.base })
  hl("Function", { fg = C.fgbright })
  hl("Statement", { fg = C.green, bold = true })
  hl("Keyword", { fg = C.green, bold = true })
  hl("Conditional", { fg = C.green, bold = true })
  hl("Repeat", { fg = C.green, bold = true })
  hl("StorageClass", { fg = C.green, bold = true })
  hl("Operator", { fg = C.green })
  hl("Type", { fg = C.cyan })
  hl("Structure", { fg = C.cyan })
  hl("Typedef", { fg = C.cyan })
  hl("PreProc", { fg = C.gold })
  hl("Macro", { fg = C.gold })
  hl("Special", { fg = C.base })
  hl("Delimiter", { fg = C.base })
  hl("Underlined", { fg = C.cyan, underline = true })
  hl("Error", { fg = C.red, bold = true })
  hl("ErrorMsg", { fg = C.red, bold = true })
  hl("WarningMsg", { fg = C.amber })
  hl("Todo", { fg = C.gold })
  hl("Question", { fg = C.gold })
  hl("MoreMsg", { fg = C.green })
  hl("ModeMsg", { fg = C.green })
  hl("Title", { fg = C.green, bold = true })
  hl("Directory", { fg = C.cyan })
  hl("NonText", { fg = C.dim })
  hl("SpecialKey", { fg = C.dim })
  hl("Whitespace", { fg = C.dim })
  hl("Conceal", { fg = C.darkgreen })

  -- 光标拖影（十字准星）
  hl("CursorLine", { bg = C.cursorbg })
  hl("CursorColumn", { bg = C.cursorbg })
  hl("CursorLineNr", { fg = C.green, bold = true })
  hl("LineNr", { fg = C.dim })
  hl("CursorLineSign", { fg = C.dim })
  hl("MatchParen", { fg = C.green, bg = C.selbg, bold = true })
  hl("Visual", { bg = C.selbg })
  hl("VisualNOS", { bg = C.selbg })
  hl("Search", { fg = "#000000", bg = C.green, bold = true })
  hl("IncSearch", { fg = "#000000", bg = C.green, bold = true })
  hl("CurSearch", { fg = "#000000", bg = C.green, bold = true })

  -- 原生状态栏/标签
  hl("StatusLine", { fg = C.green, bg = C.bgdim })
  hl("StatusLineNC", { fg = C.darkgreen, bg = "NONE" })
  hl("TabLine", { fg = C.darkgreen })
  hl("TabLineSel", { fg = C.green, bold = true })
  hl("TabLineFill", { fg = C.dim })
  hl("WinSeparator", { fg = C.dim })
  hl("VertSplit", { fg = C.dim })
  hl("TacticalBranch", { fg = C.amber, bold = true })
  hl("TacticalDiagE", { fg = C.red, bold = true })
  hl("TacticalDiagW", { fg = C.amber, bold = true })
  hl("TacticalFT", { fg = C.cyan })

  -- 启动页（固定磷光绿，不跟随配色方案）
  hl("SnacksDashboardHeader", { fg = C.green, bold = true })
  hl("SnacksDashboardTitle", { fg = C.green, bold = true })
  hl("SnacksDashboardKey", { fg = C.green, bold = true })
  hl("SnacksDashboardIcon", { fg = C.green })
  hl("SnacksDashboardDesc", { fg = C.base })
  hl("SnacksDashboardFooter", { fg = C.darkgreen })
  hl("SnacksDashboardSpecial", { fg = C.amber })
  hl("SnacksDashboardNormal", { fg = C.base })
  hl("SnacksDashboardTerminal", { fg = C.base })

  -- which-key（纯文本提示，固定绿系）
  hl("WhichKey", { fg = C.green, bold = true })
  hl("WhichKeyGroup", { fg = C.cyan, bold = true })
  hl("WhichKeyDesc", { fg = C.base })
  hl("WhichKeySeparator", { fg = C.dim })
  hl("WhichKeyValue", { fg = C.amber })
  hl("WhichKeyBorder", { fg = C.dim })

  -- picker（固定绿系）
  hl("SnacksPickerIcon", { fg = C.green, bold = true })
  hl("SnacksPickerDir", { fg = C.cyan })
  hl("SnacksPickerTitle", { fg = C.green, bold = true })
  hl("SnacksPickerBorder", { fg = C.dim })
  hl("SnacksPickerFile", { fg = C.base })
  hl("SnacksPickerPreviewTitle", { fg = C.green, bold = true })

  -- 补全面板
  hl("Pmenu", { fg = C.base, bg = C.bgdim })
  hl("PmenuSel", { fg = "#000000", bg = C.green, bold = true })
  hl("PmenuSbar", { bg = C.cursorbg })
  hl("PmenuThumb", { bg = C.selbg })
  hl("NormalFloat", { fg = C.base, bg = C.bgdim })
  hl("FloatBorder", { fg = C.dim })
  hl("FloatTitle", { fg = C.green, bold = true })

  -- 折叠/符号栏
  hl("SignColumn", { bg = "NONE", fg = C.dim })
  hl("FoldColumn", { fg = C.dim })
  hl("Folded", { fg = C.darkgreen, bg = C.cursorbg })

  -- 诊断
  hl("DiagnosticError", { fg = C.red })
  hl("DiagnosticWarn", { fg = C.amber })
  hl("DiagnosticInfo", { fg = C.green })
  hl("DiagnosticHint", { fg = C.darkgreen })
  hl("DiagnosticUnnecessary", { fg = C.darkgreen })
  hl("DiagnosticUnderlineError", { fg = C.red, underline = true })
  hl("DiagnosticUnderlineWarn", { fg = C.amber, underline = true })
  hl("DiagnosticUnderlineInfo", { fg = C.green, underline = true })
  hl("DiagnosticUnderlineHint", { fg = C.darkgreen, underline = true })
  hl("DiagnosticSignError", { fg = C.red, bold = true })
  hl("DiagnosticSignWarn", { fg = C.amber, bold = true })
  hl("DiagnosticSignInfo", { fg = C.green, bold = true })
  hl("DiagnosticSignHint", { fg = C.darkgreen, bold = true })
  hl("DiagnosticVirtualTextError", { fg = C.red })
  hl("DiagnosticVirtualTextWarn", { fg = C.amber })
  hl("DiagnosticVirtualTextInfo", { fg = C.green })
  hl("DiagnosticVirtualTextHint", { fg = C.darkgreen })
  hl("DiagnosticFloatingError", { fg = C.red })
  hl("DiagnosticFloatingWarn", { fg = C.amber })
  hl("DiagnosticFloatingInfo", { fg = C.green })
  hl("DiagnosticFloatingHint", { fg = C.darkgreen })

  -- LSP
  hl("LspReferenceText", { bg = C.cursorbg })
  hl("LspReferenceRead", { bg = C.cursorbg })
  hl("LspReferenceWrite", { bg = C.cursorbg })
  hl("LspInlayHint", { fg = C.darkgreen })
  hl("LspCodeLens", { fg = C.dim })
  hl("LspSignatureActiveParameter", { fg = C.green, bg = C.selbg, bold = true })

  -- git/diff
  hl("GitSignsAdd", { fg = C.green, bold = true })
  hl("GitSignsChange", { fg = C.amber, bold = true })
  hl("GitSignsDelete", { fg = C.red, bold = true })
  hl("DiffAdd", { fg = C.green, bg = C.cursorbg })
  hl("DiffChange", { fg = C.amber })
  hl("DiffDelete", { fg = C.red, bg = C.cursorbg })
  hl("DiffText", { fg = C.green, bg = C.selbg, bold = true })

  -- Treesitter
  local ts = {
    ["@comment"] = { fg = C.darkgreen },
    ["@comment.todo"] = { fg = C.gold },
    ["@keyword"] = { fg = C.green, bold = true },
    ["@keyword.function"] = { fg = C.green, bold = true },
    ["@keyword.operator"] = { fg = C.green, bold = true },
    ["@keyword.return"] = { fg = C.green, bold = true },
    ["@conditional"] = { fg = C.green, bold = true },
    ["@repeat"] = { fg = C.green, bold = true },
    ["@storageclass"] = { fg = C.green, bold = true },
    ["@include"] = { fg = C.green, bold = true },
    ["@exception"] = { fg = C.amber },
    ["@operator"] = { fg = C.green },
    ["@string"] = { fg = C.amber },
    ["@string.escape"] = { fg = C.gold },
    ["@character"] = { fg = C.amber },
    ["@constant"] = { fg = C.amber },
    ["@constant.builtin"] = { fg = C.gold },
    ["@macro"] = { fg = C.gold },
    ["@number"] = { fg = C.gold },
    ["@boolean"] = { fg = C.gold },
    ["@property"] = { fg = C.base },
    ["@field"] = { fg = C.base },
    ["@parameter"] = { fg = C.base },
    ["@variable"] = { fg = C.base },
    ["@variable.builtin"] = { fg = C.amber },
    ["@variable.member"] = { fg = C.base },
    ["@type"] = { fg = C.cyan },
    ["@type.builtin"] = { fg = C.cyan, bold = true },
    ["@structure"] = { fg = C.cyan },
    ["@namespace"] = { fg = C.cyan },
    ["@preproc"] = { fg = C.gold },
    ["@function"] = { fg = C.fgbright },
    ["@function.call"] = { fg = C.fgbright },
    ["@function.method"] = { fg = C.fgbright },
    ["@method"] = { fg = C.fgbright },
    ["@function.macro"] = { fg = C.gold },
    ["@constructor"] = { fg = C.fgbright },
    ["@punctuation"] = { fg = C.dim },
    ["@punctuation.special"] = { fg = C.gold },
    ["@label"] = { fg = C.gold },
    ["@attribute"] = { fg = C.amber },
    ["@tag"] = { fg = C.cyan },
    ["@tag.attribute"] = { fg = C.amber },
    ["@tag.delimiter"] = { fg = C.dim },
    ["@error"] = { fg = C.red },
  }
  for name, val in pairs(ts) do
    hl(name, val)
  end

  -- LSP semantic tokens 主要组
  local lsp = {
    ["@lsp.type.keyword"] = { fg = C.green, bold = true },
    ["@lsp.type.namespace"] = { fg = C.cyan },
    ["@lsp.type.class"] = { fg = C.cyan },
    ["@lsp.type.struct"] = { fg = C.cyan },
    ["@lsp.type.enum"] = { fg = C.cyan },
    ["@lsp.type.interface"] = { fg = C.cyan },
    ["@lsp.type.typeParameter"] = { fg = C.cyan },
    ["@lsp.type.function"] = { fg = C.fgbright },
    ["@lsp.type.method"] = { fg = C.fgbright },
    ["@lsp.type.property"] = { fg = C.base },
    ["@lsp.type.variable"] = { fg = C.base },
    ["@lsp.type.parameter"] = { fg = C.base },
    ["@lsp.type.constant"] = { fg = C.amber },
    ["@lsp.type.number"] = { fg = C.gold },
    ["@lsp.type.comment"] = { fg = C.darkgreen },
  }
  for name, val in pairs(lsp) do
    hl(name, val)
  end
end

local function git_branch()
  local root = vim.fs.find({ ".git" }, { upward = true, path = vim.fn.expand("%:p:h") })[1]
  if not root then
    return nil
  end
  local out = vim.fn.system({ "git", "-C", vim.fn.fnamemodify(root, ":h"), "branch", "--show-current" })
  if vim.v.shell_error == 0 then
    local b = vim.trim(out)
    if b ~= "" then
      return b
    end
  end
  return nil
end

local function esc(s)
  return s:gsub("%%", "%%%%")
end

-- 原生极简状态栏：分支 / 路径 / 修改标记 / 诊断 / 类型 / 行列 / 百分比
function M.stl()
  local name = vim.fn.expand("%:p:~:.")
  if name == "" then
    name = "[No Name]"
  end
  local flags = ""
  if vim.bo.modified then
    flags = "  [+]"
  elseif vim.bo.readonly then
    flags = "  [RO]"
  end
  local branch = git_branch()
  local diag = vim.diagnostic.count(0)
  local parts = {}
  local e = diag[vim.diagnostic.severity.ERROR] or 0
  local w = diag[vim.diagnostic.severity.WARN] or 0
  if e > 0 then
    parts[#parts + 1] = "%#TacticalDiagE#E" .. e
  end
  if w > 0 then
    parts[#parts + 1] = "%#TacticalDiagW#W" .. w
  end
  local diagstr = ""
  if #parts > 0 then
    diagstr = table.concat(parts, " ") .. "%#StatusLine#"
  end
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "?"
  local left = branch
      and "%#TacticalBranch#" .. esc(branch) .. " %#StatusLine#" .. esc(name)
    or esc(name)
  left = left .. esc(flags)
  local right = diagstr
    .. " %#TacticalFT#"
    .. esc(ft)
    .. "%#StatusLine# %l:%c %p%%"
  return left .. "%=" .. right
end

function M.apply()
  if not vim.g.tactical then
    return
  end
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      M.set_highlights()
    end,
  })
  M.set_highlights()
end

return M
