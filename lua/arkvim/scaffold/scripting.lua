-- arkvim/scaffold/scripting.lua — 脚本 / 系统语言 / 区块链模板
-- Lua(LOVE / Neovim) / Perl / Bash / Nix / Solidity
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

-- ===== LÖVE (Lua 游戏引擎) =====
gen.love = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["conf.lua"] = util.fill([[function love.conf(t)
  t.window.title = "{{NAME}}"
  t.window.width = 800
  t.window.height = 600
end
]], t),
    ["main.lua"] = util.fill([[function love.load()
end

function love.update(dt)
end

function love.draw()
  love.graphics.print("Hello from {{NAME}}!", 20, 20)
end
]], t),
    ["Makefile"] = "run:\n\tlove .\n\n.PHONY: run\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nLÖVE 2D 游戏项目\n\n```bash\nlove .\n```\n", t),
    [".gitignore"] = "*.love\n",
  })
  return "LÖVE (Lua 游戏) 已生成"
end

-- ===== Neovim 插件 =====
gen.nvim_plugin = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["lua/" .. t.snake .. "/init.lua"] = util.fill([[local M = {}

M.config = {
  enabled = true,
}

---@param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  if M.config.enabled then
    vim.notify("{{NAME}} loaded")
  end
end

---示例 API
function M.hello()
  vim.notify("Hello from {{NAME}}!")
end

return M
]], t),
    ["plugin/" .. t.snake .. ".lua"] = util.fill([[if vim.g.loaded_{{snake}} == 1 then
  return
end
vim.g.loaded_{{snake}} = 1

vim.api.nvim_create_user_command("{{Pascal}}Hello", function()
  require("{{snake}}").hello()
end, { desc = "{{NAME}}: 打招呼" })
]], t),
    ["README.md"] = util.fill([[# {{NAME}}

Neovim 插件模板。

## 使用

\`\`\`lua
{
  "you/{{kebab}}",
  config = function()
    require("{{snake}}").setup()
  end,
}
\`\`\`

命令：`:{{Pascal}}Hello`
]], t),
    [".gitignore"] = "doc/tags\n",
    ["stylua.toml"] = 'indent_type = "Spaces"\nindent_width = 2\ncolumn_width = 120\n',
  })
  return "Neovim 插件模板已生成"
end

-- ===== Perl =====
gen.perl = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["bin/" .. t.snake .. ".pl"] = util.fill([[#!/usr/bin/env perl
use strict;
use warnings;

my $name = shift // "World";
print "Hello from {{NAME}}, $name!\n";
]], t),
    ["lib/" .. t.Pascal .. ".pm"] = util.fill([[package {{Pascal}};
use strict;
use warnings;

our $VERSION = '0.1.0';

sub hello {
    my ($class, $name) = @_;
    $name //= 'World';
    return "Hello from {{NAME}}, $name!";
}

1;
]], t),
    ["cpanfile"] = "requires 'perl', '5.30';\n",
    ["Makefile"] = "run:\n\tperl bin/" .. t.snake .. ".pl\n\n.PHONY: run\n",
    [".gitignore"] = "blib/\nMakefile.old\n",
  })
  vim.fn.setfperm(target .. "/bin/" .. t.snake .. ".pl", "rwxr-xr-x")
  return "Perl 项目已生成"
end

-- ===== Bash 脚本 =====
gen.bash = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    [t.kebab .. ".sh"] = util.fill([=[#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
用法: {{kebab}}.sh [名字]
EOF
}

main() {
  local name="${1:-World}"
  echo "Hello from {{NAME}}, $name!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
]=], t),
    ["Makefile"] = "run:\n\t./" .. t.kebab .. ".sh\n\nlint:\n\tshellcheck " .. t.kebab .. ".sh\n\n.PHONY: run lint\n",
    [".gitignore"] = "*.log\n",
  })
  vim.fn.setfperm(target .. "/" .. t.kebab .. ".sh", "rwxr-xr-x")
  return "Bash 脚本已生成"
end

-- ===== Nix flake =====
gen.nix = function(target, name)
  util.write_tree(target, {
    ["flake.nix"] = util.fill([[{
  description = "{{NAME}}";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
        ];
      };
    };
}
]], util.project_tokens(name)),
    [".envrc"] = "use flake\n",
    [".gitignore"] = ".direnv/\nresult\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nnix develop\n```\n", util.project_tokens(name)),
  })
  return "Nix flake 已生成"
end

-- ===== Solidity (Foundry) =====
gen.solidity = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["foundry.toml"] = '[profile.default]\nsrc = "src"\nout = "out"\nlibs = ["lib"]\n',
    ["src/Counter.sol"] = util.fill([[// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
]], t),
    ["test/Counter.t.sol"] = [[// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }
}
]],
    ["script/Deploy.s.sol"] = '// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport {Script} from "forge-std/Script.sol";\nimport {Counter} from "../src/Counter.sol";\n\ncontract DeployScript is Script {\n    function run() external {\n        vm.startBroadcast();\n        new Counter();\n        vm.stopBroadcast();\n    }\n}\n',
    ["Makefile"] = "build:\n\tforge build\n\ntest:\n\tforge test -vvv\n\n.PHONY: build test\n",
    [".gitignore"] = "cache/\nout/\nlib/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\nforge init --force .   # 安装 forge-std 到 lib/（首次）\nforge build\nforge test\n```\n", t),
  })
  return "Solidity (Foundry) 已生成"
end

M.frameworks = {
  { label = "LÖVE (Lua 游戏)", lang = "lua", gen = gen.love, main = "main.lua",
    requires = { bins = { "love" }, pacman = { "love" } } },
  { label = "Neovim 插件 (Lua)", lang = "lua", gen = gen.nvim_plugin, main = "lua",
    requires = { bins = { "nvim" }, note = "纯 Lua，无需额外依赖" } },
  { label = "Perl", lang = "perl", gen = gen.perl, main = "",
    requires = { bins = { "perl" }, pacman = { "perl" } } },
  { label = "Bash 脚本", lang = "bash", gen = gen.bash, main = "",
    requires = { bins = { "bash" }, pacman = { "bash" } } },
  { label = "Nix flake", lang = "nix", gen = gen.nix, main = "flake.nix",
    requires = { bins = { "nix" }, pacman = { "nix" } } },
  { label = "Solidity (Foundry)", lang = "solidity", gen = gen.solidity, main = "src/Counter.sol",
    requires = { bins = { "forge" }, pacman = { "foundry" }, note = "也可用 pacman -S foundry 或 foundryup 安装" } },
}

return M
