-- neovim TTY green theme - fluorescent green
-- Only enable in TTY, no effect in desktop environment

local M = {}

-- Detect if running in TTY
function M.is_tty()
    local display = vim.fn.getenv("DISPLAY")
    local wayland = vim.fn.getenv("WAYLAND_DISPLAY")
    if display == "" and wayland == "" then
        return true
    end
    return false
end

-- Apply green theme
function M.apply()
    if not M.is_tty() then
        return false
    end

    -- Set colorscheme
    vim.g.colors_name = "green-tty"

    -- Color definitions
    local colors = {
        bg = "#001100",
        fg = "#33ff33",
        light_fg = "#66ff66",
        bright_fg = "#99ff99",
        dim_fg = "#006600",
        dark_bg = "#002200",
        accent = "#33ff33",
    }

    -- Set highlight groups
    local highlights = {
        -- Base
        Normal = { fg = colors.fg, bg = colors.bg },
        NormalNC = { fg = colors.fg, bg = colors.bg },
        NormalFloat = { fg = colors.fg, bg = colors.bg },

        -- Cursor
        Cursor = { fg = colors.bg, bg = colors.fg },
        CursorLine = { bg = colors.dark_bg },
        CursorColumn = { bg = colors.dark_bg },

        -- Selection
        Visual = { bg = colors.dark_bg },
        VisualNOS = { bg = colors.dark_bg },

        -- Search
        Search = { fg = colors.bg, bg = colors.fg },
        IncSearch = { fg = colors.bg, bg = colors.bright_fg },
        CurSearch = { fg = colors.bg, bg = colors.bright_fg },

        -- Line numbers
        LineNr = { fg = colors.dim_fg },
        CursorLineNr = { fg = colors.fg },

        -- Status line
        StatusLine = { fg = colors.fg, bg = colors.dark_bg },
        StatusLineNC = { fg = colors.dim_fg, bg = colors.dark_bg },

        -- Tab line
        TabLine = { fg = colors.dim_fg, bg = colors.dark_bg },
        TabLineFill = { bg = colors.dark_bg },
        TabLineSel = { fg = colors.fg, bg = colors.bg },

        -- Popup menu
        Pmenu = { fg = colors.fg, bg = colors.dark_bg },
        PmenuSel = { fg = colors.bg, bg = colors.fg },
        PmenuSbar = { bg = colors.dark_bg },
        PmenuThumb = { fg = colors.fg, bg = colors.bg },

        -- Separators
        WinSeparator = { fg = colors.dim_fg },

        -- Syntax highlighting
        Comment = { fg = colors.dim_fg, italic = true },
        Constant = { fg = colors.bright_fg },
        String = { fg = colors.light_fg },
        Character = { fg = colors.light_fg },
        Number = { fg = colors.bright_fg },
        Boolean = { fg = colors.bright_fg },
        Float = { fg = colors.bright_fg },

        Identifier = { fg = colors.fg },
        Function = { fg = colors.bright_fg },
        Statement = { fg = colors.fg },
        Conditional = { fg = colors.fg },
        Repeat = { fg = colors.fg },
        Label = { fg = colors.fg },
        Operator = { fg = colors.fg },
        Keyword = { fg = colors.fg },
        Exception = { fg = colors.fg },

        PreProc = { fg = colors.fg },
        Include = { fg = colors.fg },
        Define = { fg = colors.fg },
        Macro = { fg = colors.fg },
        PreCondit = { fg = colors.fg },

        Type = { fg = colors.light_fg },
        StorageClass = { fg = colors.fg },
        Structure = { fg = colors.fg },
        Typedef = { fg = colors.fg },

        Special = { fg = colors.bright_fg },
        SpecialChar = { fg = colors.bright_fg },
        Tag = { fg = colors.fg },
        Delimiter = { fg = colors.fg },
        SpecialComment = { fg = colors.dim_fg },
        Debug = { fg = colors.fg },

        -- Errors/Warnings
        Error = { fg = "#ff5555" },
        ErrorMsg = { fg = "#ff5555" },
        WarningMsg = { fg = "#66ff33" },
        MoreMsg = { fg = colors.fg },
        ModeMsg = { fg = colors.fg },

        -- Diff
        DiffAdd = { fg = colors.bright_fg, bg = colors.dark_bg },
        DiffChange = { fg = colors.fg, bg = colors.dark_bg },
        DiffDelete = { fg = "#ff5555", bg = colors.dark_bg },
        DiffText = { fg = colors.fg, bg = colors.dark_bg },

        -- Git
        gitcommitComment = { fg = colors.dim_fg },
        gitcommitUntracked = { fg = colors.light_fg },
        gitcommitDiscarded = { fg = colors.dim_fg },
        gitcommitSelected = { fg = colors.fg },
        gitcommitUnmerged = { fg = colors.bright_fg },
        gitcommitBranch = { fg = colors.fg },

        -- LSP
        DiagnosticError = { fg = "#ff5555" },
        DiagnosticWarn = { fg = "#66ff33" },
        DiagnosticInfo = { fg = colors.fg },
        DiagnosticHint = { fg = colors.light_fg },

        -- TreeSitter
        ["@keyword"] = { fg = colors.fg },
        ["@function"] = { fg = colors.bright_fg },
        ["@variable"] = { fg = colors.fg },
        ["@string"] = { fg = colors.light_fg },
        ["@comment"] = { fg = colors.dim_fg, italic = true },
    }

    -- Apply highlight groups
    for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
    end

    -- Set terminal colors
    if vim.env.TERM then
        vim.g.terminal_color_0 = "#001100"
        vim.g.terminal_color_1 = "#ff5555"
        vim.g.terminal_color_2 = "#33ff33"
        vim.g.terminal_color_3 = "#66ff33"
        vim.g.terminal_color_4 = "#33ff33"
        vim.g.terminal_color_5 = "#99ff99"
        vim.g.terminal_color_6 = "#33ff33"
        vim.g.terminal_color_7 = "#33ff33"
        vim.g.terminal_color_8 = "#002200"
        vim.g.terminal_color_9 = "#ff5555"
        vim.g.terminal_color_10 = "#33ff33"
        vim.g.terminal_color_11 = "#66ff33"
        vim.g.terminal_color_12 = "#33ff33"
        vim.g.terminal_color_13 = "#99ff99"
        vim.g.terminal_color_14 = "#33ff33"
        vim.g.terminal_color_15 = "#99ff99"
    end

    return true
end

return M
