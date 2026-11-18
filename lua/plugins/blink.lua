-- 补全细节增强（blink.cmp）
-- 目标：菜单里能看到函数签名/来源、自动文档、签名帮助、幽灵文本；
-- 同时保持 LSP 为首选来源，避免补全列表被 buffer 词淹没。
return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        providers = {
          lsp = {
            -- clangd 会在 label 前加 include 指示符（" " 或 "•"），
            -- 菜单里显示成 " NEWOEDER" 很怪，这里去掉；filterText 仍然正确。
            transform_items = function(_, items)
              for _, item in ipairs(items) do
                if item.client_name == "clangd" and type(item.label) == "string" then
                  item.label = item.label:gsub("^[ •]", "")
                end
              end
              return items
            end,
          },
        },
      },
      completion = {
        -- 补全项详情：自动显示文档（函数/类型说明）
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          update_delay_ms = 50,
          treesitter_highlighting = true,
          window = { border = "rounded", max_height = 20 },
        },
        -- 菜单：kind 图标 | 名称 + 签名 | 来源
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp", "buffer" },
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        -- 幽灵文本：选中项直接预览
        ghost_text = {
          enabled = true,
          show_with_selection = true,
          show_without_selection = true,
          show_with_menu = true,
          show_without_menu = true,
        },
        list = {
          max_items = 200,
          selection = { preselect = true, auto_insert = true },
        },
        -- 退格/关键字/触发字符时都重新弹补全；不在进入插入模式时强行弹出
        trigger = {
          show_on_backspace = true,
          show_on_backspace_in_keyword = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
          show_on_insert = false,
        },
        accept = {
          resolve_timeout_ms = 500,
        },
      },
      -- 函数参数签名帮助
      signature = {
        enabled = true,
        trigger = {
          enabled = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        window = {
          border = "rounded",
          show_documentation = true,
        },
      },
    },
  },
}
