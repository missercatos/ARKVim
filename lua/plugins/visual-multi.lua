-- mg979/vim-visual-multi: multiple cursors / multiple selections
-- 用法：
--   * 光标放在词上按 <C-n>：选中该词并继续按 <C-n> 添加下一个相同词；
--   * <M-Down>/<M-Up>：在上/下加一个光标（垂直多行同时编辑）；
--   * 多光标状态下 I / A 插入、c 修改、d 删除，Esc 退出；
--   * q 跳过当前匹配，Q 移除当前光标，n/N 下一个/上一个匹配。
-- 注意：LazyVim 默认把 <C-Down>/<C-Up> 用于调整窗口高度，会覆盖插件的
-- 垂直加光标映射，所以这里改用 Alt+上/下。
-- Docs: https://github.com/mg979/vim-visual-multi
return {
  {
    "mg979/vim-visual-multi",
    event = { "VeryLazy" },
    init = function()
      -- use the plugin defaults, but keep mouse handling native
      vim.g.VM_default_mappings = 1
      vim.g.VM_mouse_mappings = 0
      vim.g.VM_set_statusline = 0
      vim.g.VM_silent_exit = 1
      -- 输入完按一次 Esc 就退出多光标（默认要按两次）
      vim.g.VM_quit_after_leaving_insert_mode = 1
      vim.g.VM_maps = {
        ["Add Cursor Down"] = "<M-Down>",
        ["Add Cursor Up"] = "<M-Up>",
      }
    end,
  },
}
