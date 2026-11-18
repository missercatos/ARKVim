-- 远程开发（SSH）
return {
  {
    "amitds1997/remote-nvim.nvim",
    cmd = { "RemoteStart", "RemoteStop", "RemoteInfo", "RemoteCleanup" },
    keys = {
      { "<leader>Xr", "<cmd>RemoteStart<CR>", desc = "远程开发" },
    },
    config = true,
  },
}
