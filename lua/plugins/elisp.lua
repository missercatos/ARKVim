-- Emacs Lisp（.el）：语法高亮 + 自动补全
--
-- 语法高亮：nvim-treesitter(main) 的 parser registry 里没有 elisp，所以手动注册
--   Wilfred/tree-sitter-elisp，并自带 after/queries/elisp 的高亮查询。
-- 自动补全：Emacs Lisp 没有通用 LSP，这里用本机 Emacs 导出的符号表
--   （见 lua/arkvim/elisp.lua），通过 blink.cmp 的 omni(complete-func) 源接入。

local function register_parser()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok or type(parsers) ~= "table" then
    return
  end
  parsers.elisp = {
    install_info = {
      url = "https://github.com/Wilfred/tree-sitter-elisp",
      revision = "0cbf0906d9ee707c8c109422fba9cdd17ae13dcf",
    },
    tier = 2,
  }
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      -- 只在 User TSUpdate 时注册：nvim-treesitter 的安装/更新流程会 reload_parsers()
      -- 并触发该事件（安装时的 reload 发生在本 init 之后），这样既不把 lazy 插件
      -- 提前拉起来，也不会让注册好的 elisp parser 在重载时被丢掉。
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = register_parser,
      })
    end,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "elisp" })
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        providers = {
          elisp_emacs = {
            name = "Emacs",
            module = "blink.cmp.sources.complete_func",
            opts = {
              complete_func = function()
                -- 只在 elisp buffer 生效（omnifunc 由 arkvim.elisp 设置）
                if vim.bo.omnifunc:find("arkvim.elisp", 1, true) then
                  return vim.bo.omnifunc
                end
                return nil
              end,
            },
          },
        },
        per_filetype = {
          elisp = { inherit_defaults = true, "elisp_emacs" },
        },
      },
    },
  },
}
