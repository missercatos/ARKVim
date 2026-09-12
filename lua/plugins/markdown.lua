return {
  -- render-markdown: in-buffer markdown rendering (lazy: only on markdown buffers)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
    opts = {
      file_types = { "markdown", "codecompanion" },
      heading = { enabled = true },
      code = { enabled = true },
      dash = { enabled = true },
      bullet = { enabled = true },
      link = { enabled = true },
      quote = { enabled = true },
      sign = { enabled = false },
    },
  },

  -- markdown-preview.nvim: browser preview (lazy: only on markdown buffers)
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = function() vim.fn["mkdp#util#install"]() end,
    keys = {
      { "<leader>cp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview" },
    },
    config = function()
      vim.g.mkdp_auto_start = false
      vim.g.mkdp_auto_close = true
      vim.g.mkdp_refresh_slow = false
      vim.g.mkdp_browser = ""
    end,
  },

  -- img-clip: paste image from clipboard to markdown
  {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown", "tex", "html", "rst" },
    keys = {
      { "<leader>pi", function() require("img-clip").pasteImage() end, desc = "Paste image" },
    },
    opts = {
      default = {
        dir_path = "assets",
        file_name = "%Y-%m-%d-%H-%M-%S",
        url_path = "assets/",
        use_absolute_path = false,
        relative_to_current_file = true,
      },
    },
  },
}
