-- 左侧 Git 提交图谱：vim-flog（+ vim-fugitive）
-- 键位由 arkvim.gitgraph.setup() 注册；Flog 窗口内 Enter 看 commit/diff，
-- a 切换全部分支，g? 帮助，gq 关闭。
return {
  {
    "rbong/vim-flog",
    lazy = true,
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
  },
}
