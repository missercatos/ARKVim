return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          init_options = {
            fallbackFlags = {
              "-I/usr/include",
            },
          },
        },
      },
    },
  },

  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerOpen", "OverseerRun", "OverseerBuild" },
    keys = {
      { "<F5>", "<cmd>OverseerRun<cr>", desc = "运行 raylib 游戏" },
      { "<leader>cb", "<cmd>OverseerBuild<cr>", desc = "编译" },
      { "<leader>cr", "<cmd>OverseerRun<cr>", desc = "编译并运行" },
      { "<leader>co", "<cmd>OverseerOpen<cr>", desc = "打开任务面板" },
    },
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 10,
        max_height = 25,
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        opts = {
          ensure_installed = { "codelldb" },
        },
      },
    },
    keys = {
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "断点",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "单步跳过",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "单步进入",
      },
      {
        "<S-F5>",
        function()
          require("dap").terminate()
        end,
        desc = "停止调试",
      },
    },
    config = function()
      local dap = require("dap")
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "/home/a/.local/share/nvim/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.cpp = {
        {
          name = "Launch raylib game",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    keys = {
      {
        "<C-j>",
        function()
          require("luasnip").jump(1)
        end,
        mode = { "i", "s" },
      },
    },
    config = function()
      local ls = require("luasnip")
      ls.add_snippets("cpp", {
        ls.parser.parse_snippet(
          "rmain",
          [[
    #include "raylib.h"

    int main() {
        const int screenWidth = 800;
        const int screenHeight = 450;

        InitWindow(screenWidth, screenHeight, "${1:Game Title}");
        SetTargetFPS(60);

        while (!WindowShouldClose()) {
            ${2:// Update}

            BeginDrawing();
            ClearBackground(RAYWHITE);

            ${3:// Draw}
            DrawText("Hello Raylib!", 190, 200, 20, LIGHTGRAY);

            EndDrawing();
        }

        CloseWindow();
        return 0;
    }
            ]]
        ),
        ls.parser.parse_snippet(
          "rcppm",
          [[
    #include "raylib-cpp.hpp"

    int main() {
        raylib::Window window(800, 450, "${1:Game Title}");
        window.SetTargetFPS(60);

        while (!window.ShouldClose()) {
            window.BeginDrawing();
            window.ClearBackground(RAYWHITE);

            ${2:// Draw here}

            window.EndDrawing();
        }

        return 0;
    }
            ]]
        ),
        ls.parser.parse_snippet(
          "rgame",
          [[
    #include "raylib-cpp.hpp"

    class Game {
    public:
        Game(int width, int height, const char* title)
            : window(width, height, title) {
            window.SetTargetFPS(60);
        }

        void Run() {
            while (!window.ShouldClose()) {
                Update();
                Draw();
            }
        }

    private:
        raylib::Window window;

        void Update() {
            ${1:// Update logic}
        }

        void Draw() {
            window.BeginDrawing();
            window.ClearBackground(RAYWHITE);
            ${2:// Draw calls}
            window.EndDrawing();
        }
    };

    int main() {
        Game game(800, 450, "My Game");
        game.Run();
        return 0;
    }
            ]]
        ),
      })
    end,
  },
}
