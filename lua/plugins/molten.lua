return {
  -- molten-nvim: Jupyter inline output
  -- 按需加载：只在按 <leader>ji 等键时加载。
  -- 注意：.ipynb 的 ft 是 json 而不是 jupyter，所以不能用 ft 触发；
  -- 之前用 ft={"python","jupyter"} 会导致打开任何 .py 都加载 molten。
  -- rplugin manifest 也不在启动时加载，由 arkvim.mobile.molten_ensure() 按需注册。
  {
    "benlubas/molten-nvim",
    keys = {
      { "<leader>ji", function() require("arkvim.mobile").molten_init() end, desc = "Jupyter 初始化" },
      { "<leader>jl", function() require("arkvim.mobile").molten_cmd("MoltenEvaluateLine") end, desc = "Run Line" },
      { "<leader>jr", function() require("arkvim.mobile").molten_cmd("MoltenReevaluateCell") end, desc = "Re-evaluate Cell" },
      { "<leader>jo", function() require("arkvim.mobile").molten_cmd("MoltenOpenInBrowser") end, desc = "Open in Browser" },
    },
    config = function()
      vim.g.molten_output_type = "window"
      vim.g.molten_auto_open_output = true
      vim.g.molten_cover_comment_start_end = true
      vim.g.molten_image_provider = "snacks.nvim"
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
    end,
  },

  -- sniprun: inline code execution
  -- 仅 Unix：它的安装脚本是 bash，且不支持 Windows
  {
    "michaelb/sniprun",
    enabled = vim.fn.has("unix") == 1,
    build = "bash install.sh",
    cmd = { "SnipRun", "SnipReset", "SnipInfo" },
    keys = {
      { "<leader>js", "<cmd>SnipRun<CR>", desc = "Run snippet", mode = { "n", "x" } },
      { "<leader>jc", "<cmd>SnipClose<CR>", desc = "Close output" },
    },
    config = function()
      require("sniprun").setup({
        display = { "TemporaryCodeResult" },
        inline_handlers = {},
      })
    end,
  },
}
