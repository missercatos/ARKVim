-- folke/noice.nvim: fancy UI for messages, cmdline, LSP progress
-- NOTE: the startup ASCII header is a Snacks *dashboard terminal section*,
-- not a message/cmdline, so noice never removes it. UI stays unchanged.
--
-- In tactical terminals noice is disabled (see plugins/tactical.lua).
local enabled = not vim.g.tactical

return {
  {
    "folke/noice.nvim",
    enabled = enabled,
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-notify",
    },
    {
      "rcarriga/nvim-notify",
      opts = {
        -- transparent background; give notify a concrete colour so it
        -- does not warn about a missing NotifyBackground highlight group
        background_colour = "#1a1b26",
        timeout = 3000,
      },
    },
    opts = {
      cmdline = {
        enabled = true, -- replaces the native command line
        view = "cmdline_popup",
      },
      messages = {
        enabled = true, -- replaces `:messages`
        view = "mini",
      },
      notify = {
        enabled = true, -- takes over vim.notify (via nvim-notify)
      },
      popupmenu = {
        enabled = false, -- blink.cmp / native cmdline completion keep their own UI
      },
      lsp = {
        progress = {
          enabled = true, -- LSP progress as popup
          view = "mini",
        },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages open in a split
        inc_rename = false, -- use the native `:IncRename`
        lsp_doc_border = true, -- add a border to hover docs
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
              { find = "%d+ lines" },
              { find = "已写入" },
              { find = "written" },
            },
          },
          view = "mini",
        },
      },
    },
  },
  {
    -- noice now owns notifications/messages; disable the Snacks notifier
    -- to avoid double toasts (the ascii dashboard is untouched)
    "folke/snacks.nvim",
    opts = {
      notifier = {
        enabled = false,
      },
    },
  },
}
