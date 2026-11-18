local enabled = vim.fn.executable("clangd") == 1

--- 没有 compile_commands.json / compile_flags.txt 时给 clangd 的兜底 include 路径。
--- 目的：`#include "myfile.h"`（头文件在 include/、src/ 等子目录）也能补全函数/结构体/宏。
--- 有编译数据库时 clangd 会忽略 fallbackFlags，所以这里加上不会干扰正常项目。
---@param root string?
---@return string[]
local function fallback_include_flags(root)
  local file = vim.api.nvim_buf_get_name(0)
  local file_dir = file ~= "" and vim.fs.dirname(file) or nil
  if not root or root == "" then
    root = file_dir or vim.fn.getcwd()
  end

  local dirs = {
    root,
    root .. "/include",
    root .. "/inc",
    root .. "/src",
    root .. "/headers",
    root .. "/third_party/include",
    root .. "/vendor/include",
    root .. "/deps/include",
  }

  -- 简单项目（没有 .git/Makefile，root 探测不到）：
  -- 把当前文件所在目录和上一层也作为 include 路径。
  if file_dir then
    dirs[#dirs + 1] = file_dir
    dirs[#dirs + 1] = file_dir .. "/include"
    local parent = vim.fs.dirname(file_dir)
    dirs[#dirs + 1] = parent
    dirs[#dirs + 1] = parent .. "/include"
  end

  -- 一层子目录里的常见 include（例如 libs/foo/include）
  for _, pattern in ipairs({ "/*/include", "/*/inc" }) do
    local matches = vim.fn.glob(root .. pattern, false, true)
    vim.list_extend(dirs, matches)
  end

  local seen, flags = {}, {}
  for _, dir in ipairs(dirs) do
    if dir ~= "" and dir ~= "/" and vim.fn.isdirectory(dir) == 1 and not seen[dir] then
      seen[dir] = true
      flags[#flags + 1] = "-I" .. dir
    end
  end
  return flags
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = enabled,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "c", "cpp" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    enabled = enabled,
    opts = {
      servers = {
        clangd = {
          -- 不要截断结果：头文件/系统头很多时，函数容易排在 100 条之外
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--limit-results=500",
          },
          before_init = function(params, config)
            params.initializationOptions = params.initializationOptions or {}
            params.initializationOptions.fallbackFlags = fallback_include_flags(config.root_dir)
          end,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    enabled = enabled,
    optional = true,
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    enabled = enabled,
    optional = true,
    opts = {
      linters_by_ft = {
        c = { "clangtidy" },
        cpp = { "clangtidy" },
      },
      linters = {
        clangtidy = {
          -- 有 compile_commands.json 才跑 clang-tidy（否则没有 include/宏定义，误报会很多）
          condition = function(ctx)
            return vim.fs.find("compile_commands.json", { upward = true, path = ctx.dirname })[1] ~= nil
          end,
          prepend_args = {
            "-p",
            function()
              local f = vim.fs.find("compile_commands.json", {
                upward = true,
                path = vim.fn.expand("%:p:h"),
              })[1]
              return f and vim.fs.dirname(f) or "."
            end,
          },
        },
      },
    },
  },
}
